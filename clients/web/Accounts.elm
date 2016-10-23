module Accounts exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (style, placeholder, type', href, value)
import Html.Events exposing (..)
import Json.Encode
import Json.Decode exposing (Decoder, string, list)
import Json.Decode.Pipeline exposing (decode, required)
import Http
import Task
import Utils exposing (..)


-- MODEL


type alias Account =
    { id : String
    , name : String
    , email : String
    , created : String
    , modified : String
    }


initAccount : Account
initAccount =
    (Account "" "" "" "" "")


type alias Session =
    { account : Account
    , token : String
    }


initSession : Session
initSession =
    (Session initAccount "")


type alias Model =
    { name : String
    , email : String
    , password : String
    , isRegistering : Bool
    , session : Session
    , error : String
    }


init : Model
init =
    (Model "" "" "" False initSession "")



-- UPDATE


type Msg
    = NoOp
    | Connect
    | ConnectSucceed Session
    | ConnectFail Http.Error
    | Register
    | RegisterSucceed Session
    | RegisterFail Http.Error
    | Registering Bool
    | Disconnect
    | ChangeName String
    | ChangeEmail String
    | ChangePassword String
    | ClearError


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Connect ->
            ( model, connect model )

        ConnectSucceed session ->
            ( { model | session = session }, Cmd.none )

        ConnectFail err ->
            ( { model | error = (errorMapper err) }, Cmd.none )

        Register ->
            ( model, register model )

        RegisterSucceed session ->
            ( { model | session = session }, Cmd.none )

        RegisterFail err ->
            ( { model | error = (errorMapper err) }, Cmd.none )

        Registering bool ->
            ( { model | isRegistering = bool, error = "" }, Cmd.none )

        Disconnect ->
            ( init, Cmd.none )

        ChangeName name ->
            ( { model | name = name }, Cmd.none )

        ChangeEmail email ->
            ( { model | email = email }, Cmd.none )

        ChangePassword password ->
            ( { model | password = password }, Cmd.none )

        ClearError ->
            ( { model | error = "" }, Cmd.none )


connect : Model -> Cmd Msg
connect model =
    let
        json =
            [ ( "identifier", Json.Encode.string model.email )
            , ( "password", Json.Encode.string model.password )
            ]

        task =
            rpc "account.connect" "" json
                |> Http.fromJson decodeSession
    in
        task
            |> Task.perform ConnectFail ConnectSucceed


register : Model -> Cmd Msg
register model =
    let
        json =
            [ ( "name", Json.Encode.string model.name )
            , ( "email", Json.Encode.string model.email )
            , ( "password", Json.Encode.string model.password )
            ]

        task =
            rpc "account.register" "" json
                |> Http.fromJson decodeSession
    in
        task
            |> Task.perform RegisterFail RegisterSucceed


decodeAccount : Decoder Account
decodeAccount =
    decode Account
        |> required "id" string
        |> required "name" string
        |> required "email" string
        |> required "created" string
        |> required "modified" string


decodeSession : Decoder Session
decodeSession =
    decode Session
        |> required "account" decodeAccount
        |> required "token" string



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ viewError model.error, viewForm model ]


viewForm : Model -> Html Msg
viewForm model =
    if model.session.token /= "" then
        viewSession model.session
    else if model.isRegistering then
        viewRegisterForm model
    else
        viewConnectForm model


viewConnectForm : Model -> Html Msg
viewConnectForm model =
    div []
        [ form []
            [ input [ placeholder "Email", onInput ChangeEmail, style inputStyle, value model.email ] []
            , input [ placeholder "Password", onInput ChangePassword, type' "password", style inputStyle, value model.password, onEnter Connect ] []
            ]
        , p [] [ a [ onClick (Registering True), href "#" ] [ text "Create an account?" ] ]
        ]


viewRegisterForm : Model -> Html Msg
viewRegisterForm model =
    div []
        [ form []
            [ input [ placeholder "Name", onInput ChangeName, style inputStyle, value model.name ] []
            , input [ placeholder "Email", onInput ChangeEmail, style inputStyle, value model.email ] []
            , input [ placeholder "Password", onInput ChangePassword, type' "password", style inputStyle, value model.password, onEnter Register ] []
            ]
        , p [] [ a [ onClick (Registering False), href "#" ] [ text "Already have an account?" ] ]
        ]


viewSession : Session -> Html Msg
viewSession session =
    div []
        [ span [] [ text session.account.name ]
        , button [ onClick Disconnect ] [ text "Logout" ]
        ]


viewError : String -> Html Msg
viewError error =
    let
        out =
            if error /= "" then
                div [ style [ ( "color", "red" ) ] ]
                    [ p [] [ text error ]
                    , button [ onClick ClearError ] [ text "OK" ]
                    ]
            else
                span [] []
    in
        out


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        tagger code =
            if code == 13 then
                msg
            else
                NoOp
    in
        on "keydown" (Json.Decode.map tagger keyCode)



-- STYLES


inputStyle : List ( String, String )
inputStyle =
    [ ( "display", "block" ) ]


errorStyle : List ( String, String )
errorStyle =
    [ ( "color", "red" ) ]
