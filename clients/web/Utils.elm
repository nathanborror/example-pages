module Utils exposing (..)

import Json.Encode exposing (object, encode, Value)
import Task exposing (Task)
import Http


-- RPC Task


rpc : String -> String -> List ( String, Value ) -> Task Http.RawError Http.Response
rpc method token json =
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



-- Error Mapper


errorMapper : Http.Error -> String
errorMapper err =
    case err of
        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.UnexpectedPayload exp ->
            "UnexpectedPayload: " ++ exp

        Http.BadResponse code exp ->
            "Bad Response: " ++ exp
