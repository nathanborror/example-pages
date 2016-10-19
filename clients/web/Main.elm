module Main exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Task
import Accounts


main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { accounts : Accounts.Model }


init : ( Model, Cmd Msg )
init =
    ( Model Accounts.init, Cmd.none )



-- UPDATE


type Msg
    = AccountsMsg Accounts.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AccountsMsg subMsg ->
            let
                ( updated, cmd ) =
                    Accounts.update subMsg model.accounts
            in
                ( { model | accounts = updated }, Cmd.map AccountsMsg cmd )



-- VIEW


view : Model -> Html Msg
view model =
    div [ style [ ( "padding", "36px" ), ( "font-family", "-apple-system" ) ] ]
        [ App.map AccountsMsg (Accounts.view model.accounts) ]



--  SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
