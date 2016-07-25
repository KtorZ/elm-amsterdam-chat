module Main exposing (..)

import WebSocket
import Platform.Cmd
import Platform.Sub
import Html exposing (..)
import Html.App exposing (program)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias Model =
    { messages : List String
    , input : String
    }


socketAddress : String
socketAddress =
    "ws://localhost:3000"


init : ( Model, Cmd Msg )
init =
    ( { messages = []
      , input = ""
      }
    , Cmd.none
    )


type Msg
    = SocketMsg String
    | Send
    | Input String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SocketMsg str ->
            ( { model | messages = model.messages ++ [ str ] }, Cmd.none )

        Send ->
            ( { model | input = "" }, WebSocket.send socketAddress model.input )

        Input str ->
            ( { model | input = str }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen socketAddress SocketMsg


view : Model -> Html Msg
view model =
    let
        messages =
            List.map (\x -> p [] [ text x ]) model.messages
    in
        div [ class "container" ]
            [ div [ class "messages" ] messages
            , Html.form [ class "controls", onSubmit Send ]
                [ input [ type' "text", onInput Input, value model.input ] []
                , button [ type' "submit" ] [ text "send" ]
                ]
            ]


main : Platform.Program Never
main =
    program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
