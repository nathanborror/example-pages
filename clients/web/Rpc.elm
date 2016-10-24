module Rpc exposing (..)

import Json.Encode exposing (object, encode)
import Json.Encode
import Json.Decode exposing (Decoder, decodeString, string, int)
import Json.Decode.Pipeline exposing (decode, required)
import Task exposing (Task)
import Http exposing (RawError, Error, Response, Value(..))
import Http


-- SEND


send : String -> String -> List ( String, Json.Encode.Value ) -> Task RawError Response
send method token json =
    let
        url =
            "http://localhost:8081/" ++ method

        body =
            json
                |> object
                |> encode 0
                |> Http.string

        request =
            { verb = "POST"
            , headers = [ ( "Content-Type", "application/json" ), ( "Grpc-Metadata-token", token ) ]
            , url = url
            , body = body
            }
    in
        Http.send Http.defaultSettings request



-- JSON


fromJson : Decoder a -> Task RawError Response -> Task Error a
fromJson decoder response =
    let
        decode str =
            case decodeString decoder str of
                Ok v ->
                    Task.succeed v

                Err msg ->
                    Task.fail (UnexpectedPayload msg)
    in
        Task.mapError promoteError response
            `Task.andThen` handleResponse decode


handleResponse : (String -> Task Error a) -> Response -> Task Error a
handleResponse handle response =
    case 200 <= response.status && response.status < 300 of
        False ->
            case response.value of
                Text str ->
                    case decodeString decodeErrorResponse str of
                        Ok v ->
                            Task.fail (RpcError response.status v)

                        Err msg ->
                            Task.fail (BadResponse response.status msg)

                _ ->
                    Task.fail (BadResponse response.status response.statusText)

        True ->
            case response.value of
                Text str ->
                    handle str

                _ ->
                    Task.fail (UnexpectedPayload "Response body is a blob, expecting a string.")


promoteError : RawError -> Error
promoteError rawError =
    case rawError of
        Http.RawTimeout ->
            Timeout

        Http.RawNetworkError ->
            NetworkError



-- ERRORS


type Error
    = Timeout
    | NetworkError
    | UnexpectedPayload String
    | RpcError Int ErrorResponse
    | BadResponse Int String


type alias ErrorResponse =
    { code : Int
    , message : String
    }


decodeErrorResponse : Decoder ErrorResponse
decodeErrorResponse =
    decode ErrorResponse
        |> required "Code" int
        |> required "Error" string


errorToString : Error -> String
errorToString err =
    case err of
        Timeout ->
            "Timeout"

        NetworkError ->
            "Network Error"

        UnexpectedPayload exp ->
            "Unexpected Payload: " ++ exp

        RpcError code resp ->
            resp.message

        BadResponse code exp ->
            "Bad Response: " ++ exp
