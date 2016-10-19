module Accounts exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (style, placeholder, type', href)
import Html.Events exposing (..)
import Json.Encode
import Json.Decode exposing (Decoder, string, list)
import Json.Decode.Pipeline exposing (decode, required)
import Http
import Task


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
    (Account "" "" "" "" "" "")


type alias Session =
    { account : Account
    , token : String
    }


initSession : Session
initSession =
    (Session initAccount "")


type alias Model =
    { identifier : String
    , name : String
    , email : String
    , password : String
    , isRegistering : Bool
    , session : Session
    , error : String
    }


init : Model
init =
    (Model "" "" "" "" "" False initSession "")



-- UPDATE


type Msg
    = Connect
    | ConnectSucceed Session
    | ConnectFail Http.Error
    | Register
    | RegisterSucceed Session
    | RegisterFail Http.Error
    | Registering Bool
    | ChangeIdentifier String
    | ChangeName String
    | ChangeEmail String
    | ChangePassword String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        ChangeIdentifier identifier ->
            ( { model | identifier = identifier }, Cmd.none )

        ChangeName name ->
            ( { model | name = name }, Cmd.none )

        ChangeEmail email ->
            ( { model | email = email }, Cmd.none )

        ChangePassword password ->
            ( { model | password = password }, Cmd.none )


connect : Model -> Cmd Msg
connect model =
    let
        url =
            "http://localhost:8080/api/account.connect"

        json =
            [ ( "identifier", Json.Encode.string model.identifier )
            , ( "password", Json.Encode.string model.password )
            ]

        body =
            json
                |> Json.Encode.object
                |> Json.Encode.encode 0
                |> Http.string

        request =
            { verb = "POST"
            , headers = [ ( "Content-Type", "application/json" ) ]
            , url = url
            , body = body
            }

        task =
            Http.send Http.defaultSettings request
                |> Http.fromJson decodeSession
    in
        task
            |> Task.perform ConnectFail ConnectSucceed


register : Model -> Cmd Msg
register model =
    let
        url =
            "http://localhost:8080/api/account.register"

        json =
            [ ( "name", Json.Encode.string model.name )
            , ( "email", Json.Encode.string model.email )
            , ( "password", Json.Encode.string model.password )
            ]

        body =
            json
                |> Json.Encode.object
                |> Json.Encode.encode 0
                |> Http.string

        request =
            { verb = "POST"
            , headers = [ ( "Content-Type", "application/json" ) ]
            , url = url
            , body = body
            }

        task =
            Http.send Http.defaultSettings request
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
    let
        form =
            if model.session.token /= "" then
                authenticated model.session
            else if model.isRegistering then
                registerForm model
            else
                connectForm model
    in
        div [] [ form ]


connectForm : Model -> Html Msg
connectForm model =
    div []
        [ p [ style errorStyle ] [ text model.error ]
        , input [ placeholder "Name or Email", onInput ChangeIdentifier, style inputStyle ] []
        , input [ placeholder "Password", onInput ChangePassword, type' "password", style inputStyle ] []
        , button [ onClick Connect ] [ text "Connect" ]
        , div [] [ a [ onClick (Registering True), href "#" ] [ text "Sign Up" ] ]
        ]


registerForm : Model -> Html Msg
registerForm model =
    div []
        [ p [ style errorStyle ] [ text model.error ]
        , input [ placeholder "Name", onInput ChangeName, style inputStyle ] []
        , input [ placeholder "Email", onInput ChangeEmail, style inputStyle ] []
        , input [ placeholder "Password", onInput ChangePassword, type' "password", style inputStyle ] []
        , button [ onClick Register ] [ text "Register" ]
        , div [] [ a [ onClick (Registering False), href "#" ] [ text "Log In" ] ]
        ]


authenticated : Session -> Html Msg
authenticated session =
    div []
        [ p [] [ text session.account.name ]
        ]


inputStyle : List ( String, String )
inputStyle =
    [ ( "display", "block" ) ]


errorStyle : List ( String, String )
errorStyle =
    [ ( "color", "red" ) ]


errorMapper : Http.Error -> String
errorMapper err =
    case err of
        Http.UnexpectedPayload exp ->
            exp

        Http.BadResponse code exp ->
            exp

        otherwise ->
            ""
