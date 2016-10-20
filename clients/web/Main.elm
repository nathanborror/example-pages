module Main exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Task
import Accounts
import Pages


main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { accounts : Accounts.Model
    , pages : Pages.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model Accounts.init Pages.init, Cmd.none )



-- UPDATE


type Msg
    = AccountsMsg Accounts.Msg
    | PagesMsg Pages.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AccountsMsg subMsg ->
            let
                ( updated, cmd ) =
                    Accounts.update subMsg model.accounts
            in
                ( { model | accounts = updated }, Cmd.map AccountsMsg cmd )

        PagesMsg subMsg ->
            let
                ( updated, cmd ) =
                    Pages.update subMsg model.pages
            in
                ( { model | pages = updated }, Cmd.map PagesMsg cmd )



-- VIEW


view : Model -> Html Msg
view model =
    div [ style [ ( "padding", "36px" ), ( "font-family", "-apple-system" ) ] ]
        [ App.map AccountsMsg (Accounts.view model.accounts)
        , App.map PagesMsg (Pages.view model.pages)
        ]



--  SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
