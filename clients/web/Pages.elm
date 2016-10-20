module Pages exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (style, placeholder, type', href)
import Html.Events exposing (..)
import Json.Encode
import Json.Decode exposing (Decoder, string, int, list, at)
import Json.Decode.Pipeline exposing (decode, required)
import Http
import Task
import Accounts


-- MODEL


type alias Page =
    { id : String
    , account : Accounts.Account
    , text : String
    , created : String
    , modified : String
    }


initPage : Page
initPage =
    (Page "" Accounts.initAccount "" "" "")


type alias Model =
    { pages : List Page
    , text : String
    , error : String
    }


init : Model
init =
    (Model [] "" "")



-- UPDATE


type Msg
    = List
    | ListSucceed (List Page)
    | ListFail Http.Error
    | Create
    | CreateSucceed Page
    | CreateFail Http.Error
    | ChangeText String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        List ->
            ( model, listPages model )

        ListSucceed pages ->
            ( { model | pages = pages }, Cmd.none )

        ListFail err ->
            ( { model | error = (errorMapper err) }, Cmd.none )

        Create ->
            ( model, createPage model )

        CreateSucceed page ->
            ( { model | pages = List.append model.pages [ page ] }, Cmd.none )

        CreateFail err ->
            ( { model | error = (errorMapper err) }, Cmd.none )

        ChangeText text ->
            ( { model | text = text }, Cmd.none )


listPages : Model -> Cmd Msg
listPages model =
    let
        url =
            "http://localhost:8081/pages"
    in
        Task.perform ListFail ListSucceed (Http.get decodePages url)


createPage : Model -> Cmd Msg
createPage model =
    let
        url =
            "http://localhost:8081/page.create"

        json =
            [ ( "text", Json.Encode.string model.text ) ]

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
                |> Http.fromJson decodePage
    in
        task
            |> Task.perform CreateFail CreateSucceed


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "id" string
        |> required "account" Accounts.decodeAccount
        |> required "text" string
        |> required "created" string
        |> required "modified" string


decodePages : Decoder (List Page)
decodePages =
    at [ "pages" ] (list decodePage)



-- VIEW


view : Model -> Html Msg
view model =
    div [] [ text "Pages" ]


errorMapper : Http.Error -> String
errorMapper err =
    case err of
        Http.UnexpectedPayload exp ->
            exp

        Http.BadResponse code exp ->
            exp

        otherwise ->
            ""
