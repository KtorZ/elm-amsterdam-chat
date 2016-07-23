module Main exposing (..)

import WebSocket
import Platform.Cmd
import Platform.Sub
import Html exposing (..)
import Html.App exposing (program)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias Model =
    { texts : List String
    , input : String
    }


socketAddress : String
socketAddress =
    "ws://localhost:3000"


type Message
    = SocketMessage String
    | Send
    | Input String


init : Model
init =
    { texts = []
    , input = ""
    }


update : Message -> Model -> ( Model, Cmd Message )
update msg model =
    case msg of
        SocketMessage str ->
            ( { model | texts = model.texts ++ [ str ] }, Cmd.none )

        Send ->
            ( { model | input = "" }, WebSocket.send socketAddress model.input )

        Input str ->
            ( { model | input = str }, Cmd.none )


subscriptions : Model -> Sub Message
subscriptions model =
    WebSocket.listen socketAddress SocketMessage


view : Model -> Html Message
view model =
    let
        texts =
            List.map (\x -> p [] [ text x ]) model.texts
    in
        div [ class "container" ]
            [ div [ class "texts" ] texts
            , Html.form [ class "controls", onSubmit Send ]
                [ input [ type' "text", onInput Input, value model.input ] []
                , button [] [ text "send" ]
                ]
            ]


main : Platform.Program Never
main =
    program
        { init = ( init, Cmd.none )
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
