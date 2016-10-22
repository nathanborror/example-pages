module Utils exposing (..)

import Json.Encode exposing (object, encode, Value)
import Task exposing (Task)
import Http


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


errorMapper : Http.Error -> String
errorMapper err =
    case err of
        Http.UnexpectedPayload exp ->
            exp

        Http.BadResponse code exp ->
            exp

        otherwise ->
            ""
