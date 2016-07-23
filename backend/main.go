package main

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

// Handler implement the http.ServeHTTP method in order to be promoted to a websocket handler
type Handler struct {
	ChMsg  chan string
	ChConn chan *websocket.Conn
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Unsafe but who cares ?
	},
}

// ServeHTTP implements the http.Handler interface
func (h Handler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	conn, err := upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.Fatal(err)
	}

	h.ChConn <- conn
	go h.Listen(conn)
}

// Listen manages incoming messages and re-dispatch them to other sockets
func (h Handler) Listen(conn *websocket.Conn) {
	for {
		msgType, data, err := conn.ReadMessage()

		if err != nil {
			log.Println(err)
			continue
		}

		if msgType != websocket.TextMessage {
			log.Println("unhandled non-text message")
			continue
		}

		h.ChMsg <- string(data)
	}
}

// Dispatch broadcast messages to existing connections
func (h Handler) Dispatch() {
	var connections []*websocket.Conn

	for {
		select {
		case conn := <-h.ChConn:
			log.Println("new connection")
			connections = append(connections, conn)

		case msg := <-h.ChMsg:
			var alive []*websocket.Conn

			for _, conn := range connections {
				err := conn.WriteMessage(websocket.TextMessage, []byte(msg))
				if err != nil { // A bit aggressive
					log.Println("connection lost")
					continue
				}

				// Not efficient at all
				aliveConn := new(websocket.Conn)
				*aliveConn = *conn
				alive = append(alive, aliveConn)
			}

			connections = alive
		}
	}
}

func main() {
	h := Handler{
		ChMsg:  make(chan string),
		ChConn: make(chan *websocket.Conn),
	}

	go h.Dispatch()

	log.Println("listening on port 3000")
	log.Fatal(http.ListenAndServe("localhost:3000", h))
}
