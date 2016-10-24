module Pages exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (style, placeholder, type', href, value)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy)
import Json.Encode
import Json.Decode exposing (Decoder, string, int, list, at)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Http
import Task
import Accounts
import Rpc


-- MODEL


type alias Page =
    { id : String
    , account : Accounts.Account
    , text : String
    , created : String
    , modified : String
    }


type alias PagesSet =
    { pages : List Page
    , page : String
    , total : String
    }


initPage : Page
initPage =
    (Page "" Accounts.initAccount "" "" "")


type alias Model =
    { pages : List Page
    , text : String
    , session : Accounts.Session
    , error : String
    }


init : Model
init =
    (Model [] "" Accounts.initSession "")



-- UPDATE


type Msg
    = List
    | ListSucceed PagesSet
    | ListFail Http.Error
    | Create
    | CreateSucceed Page
    | CreateFail Rpc.Error
    | Delete String
    | DeleteSucceed Page
    | DeleteFail Rpc.Error
    | ChangeText String
    | ClearError


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        List ->
            ( model, listPages )

        ListSucceed set ->
            ( { model | pages = set.pages }, Cmd.none )

        ListFail _ ->
            ( model, Cmd.none )

        Create ->
            ( model, createPage model )

        CreateSucceed page ->
            ( { model | text = "", pages = List.append model.pages [ page ] }, Cmd.none )

        CreateFail err ->
            ( { model | error = (Rpc.errorToString err) }, Cmd.none )

        Delete id ->
            ( model, deletePage id model )

        DeleteSucceed page ->
            ( { model | pages = List.filter (\n -> n.id /= page.id) model.pages }, Cmd.none )

        DeleteFail err ->
            ( { model | error = (Rpc.errorToString err) }, Cmd.none )

        ChangeText text ->
            ( { model | text = text }, Cmd.none )

        ClearError ->
            ( { model | error = "" }, Cmd.none )


listPages : Cmd Msg
listPages =
    let
        url =
            "http://localhost:8081/pages"
    in
        Task.perform ListFail ListSucceed (Http.get decodePagesSet url)


createPage : Model -> Cmd Msg
createPage model =
    let
        json =
            [ ( "text", Json.Encode.string model.text ) ]

        task =
            Rpc.send "page.create" model.session.token json
                |> Rpc.fromJson decodePage
    in
        Task.perform CreateFail CreateSucceed task


deletePage : String -> Model -> Cmd Msg
deletePage id model =
    let
        json =
            [ ( "id", Json.Encode.string id ) ]

        task =
            Rpc.send "page.delete" model.session.token json
                |> Rpc.fromJson decodePage
    in
        Task.perform DeleteFail DeleteSucceed task



-- DECODE


decodePage : Decoder Page
decodePage =
    decode Page
        |> required "id" string
        |> required "account" Accounts.decodeAccount
        |> optional "text" string ""
        |> required "created" string
        |> required "modified" string


decodePages : Decoder (List Page)
decodePages =
    list decodePage


decodePagesSet : Decoder PagesSet
decodePagesSet =
    decode PagesSet
        |> optional "pages" decodePages []
        |> optional "page" string "0"
        |> optional "total" string "0"



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h3 [] [ text "Pages" ]
        , viewError model.error
        , viewForm model
        , Keyed.ul [] <|
            List.map viewKeyedPage model.pages
        ]


viewForm : Model -> Html Msg
viewForm model =
    form [ onSubmit Create ]
        [ input [ placeholder "Text", onInput ChangeText, value model.text ] []
        ]


viewKeyedPage : Page -> ( String, Html Msg )
viewKeyedPage page =
    ( page.id, lazy viewPage page )


viewPage : Page -> Html Msg
viewPage page =
    div []
        [ button [ onClick (Delete page.id) ] [ text "x" ]
        , span [] [ text page.text ]
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
