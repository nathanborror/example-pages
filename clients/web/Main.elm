port module Main exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Task
import Accounts
import Pages


main : Program (Maybe Model)
main =
    App.programWithFlags
        { init = init
        , view = view
        , update = updateWithStorage
        , subscriptions = \_ -> Sub.none
        }


port setStorage : Model -> Cmd msg


updateWithStorage : Msg -> Model -> ( Model, Cmd Msg )
updateWithStorage msg model =
    let
        ( newModel, cmds ) =
            update msg model
    in
        ( newModel, Cmd.batch [ setStorage newModel, cmds ] )



-- MODEL


type alias Model =
    { accounts : Accounts.Model
    , pages : Pages.Model
    }


initModel : Model
initModel =
    (Model Accounts.init Pages.init)


init : Maybe Model -> ( Model, Cmd Msg )
init savedModel =
    ( Maybe.withDefault initModel savedModel, Cmd.map PagesMsg Pages.listPages )



-- UPDATE


type Msg
    = AccountsMsg Accounts.Msg
    | PagesMsg Pages.Msg
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AccountsMsg subMsg ->
            let
                ( updated, cmd ) =
                    Accounts.update subMsg model.accounts

                pages =
                    model.pages
            in
                ( { model | accounts = updated, pages = { pages | session = updated.session } }, Cmd.map AccountsMsg cmd )

        PagesMsg subMsg ->
            let
                ( updated, cmd ) =
                    Pages.update subMsg model.pages
            in
                ( { model | pages = updated }, Cmd.map PagesMsg cmd )

        Reset ->
            ( initModel, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ style [ ( "padding", "36px" ), ( "font-family", "-apple-system" ) ] ]
        [ App.map AccountsMsg (Accounts.view model.accounts)
        , App.map PagesMsg (Pages.view model.pages)
        , button [ onClick Reset ] [ text "reset" ]
        ]
