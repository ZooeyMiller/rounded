port module Main exposing (..)

import Array exposing (..)
import Html exposing (..)
import Html.Attributes as Ha exposing (..)
import Html.Events exposing (..)
import Navigation
import Svg exposing (..)
import Svg.Attributes as Sa exposing (..)


main : Program (Maybe Model) Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- Model


type alias Model =
    { name : String
    , confirmedName : String
    , location : String
    , current : EmotionDatum
    , emotionHistory : Array EmotionDatum
    }


type alias EmotionDatum =
    { mood : String
    , energy : String
    }


init : Maybe Model -> Navigation.Location -> ( Model, Cmd Msg )
init model location =
    case model of
        Just model ->
            ( { model | location = location.pathname }, Cmd.none )

        Nothing ->
            ( Model "" "" location.pathname (EmotionDatum "5" "5") (Array.fromList []), Cmd.none )



--Update


type Msg
    = Name String
    | LoginSubmit
    | EmotionToGraph
    | EmotionToEmotion
    | UrlChange Navigation.Location
    | Mood String
    | Energy String
    | Route String
    | NoMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Name newName ->
            ( { model | name = newName }, Cmd.none )

        LoginSubmit ->
            let
                newModel =
                    { model | confirmedName = model.name }
            in
            ( newModel, Cmd.batch [ Navigation.newUrl "/mood", setStorage newModel ] )

        EmotionToGraph ->
            let
                newModel =
                    { model
                        | emotionHistory = push (emotionDatumWithFloatToInt model.current) model.emotionHistory
                        , current = EmotionDatum "5" "5"
                    }
            in
            ( newModel, Cmd.batch [ setStorage newModel, Navigation.newUrl "/graph" ] )

        EmotionToEmotion ->
            let
                newModel =
                    { model
                        | emotionHistory = push (emotionDatumWithFloatToInt model.current) model.emotionHistory
                        , current = EmotionDatum "5" "5"
                    }
            in
            ( newModel, Navigation.newUrl "/mood" )

        Mood newMood ->
            ( { model | current = setMood newMood model.current }, Cmd.none )

        Energy newEnergy ->
            ( { model | current = setEnergy newEnergy model.current }, Cmd.none )

        UrlChange newLocation ->
            ( { model | location = newLocation.pathname }, Cmd.none )

        Route location ->
            ( model, Navigation.newUrl location )

        NoMsg ->
            ( model, Cmd.none )


setEnergy : String -> EmotionDatum -> EmotionDatum
setEnergy newEnergy mood =
    { mood | energy = newEnergy }


setMood : String -> EmotionDatum -> EmotionDatum
setMood newMood mood =
    { mood | mood = newMood }


stringFloatToStringInt : String -> String
stringFloatToStringInt stringFloat =
    String.toFloat stringFloat
        |> Result.withDefault 0
        |> round
        |> toString


emotionDatumWithFloatToInt : EmotionDatum -> EmotionDatum
emotionDatumWithFloatToInt emotions =
    { emotions
        | mood = stringFloatToStringInt emotions.mood
        , energy = stringFloatToStringInt emotions.energy
    }



--View


view : Model -> Html Msg
view model =
    div [ Ha.class "flex flex-column vh-100" ]
        [ header [ Ha.class "pa3 bg-blue flex items-center white" ]
            [ span [ Ha.class "f3 ma0 tracked" ] [ Html.text "☉ rounded" ]
            , renderGraphLink model
            ]
        , div [ Ha.class "pa4 flex-auto h-100" ]
            [ main_ [ Ha.class "flex flex-column justify-center w-100 h-100 pa4 mw6 center ba br2 br4--top-right br4--bottom-left br--bottom-right b--blue bg-light-gray pa4 br2-m" ]
                [ chooseView model ]
            ]
        ]


renderGraphLink : Model -> Html Msg
renderGraphLink model =
    if model.location == "/graph" then
        nav [ Ha.class "ml-auto" ]
            [ Html.button [ onClick (Route "/mood"), Ha.class "flex items-center justify-center w2 h2 pa1 bn" ]
                [ svg [ Sa.class "w-100", fill "none", attribute "height" "32", attribute "stroke" "currentcolor", attribute "stroke-linecap" "round", attribute "stroke-linejoin" "round", attribute "stroke-width" "2", Sa.viewBox "0 0 32 32", attribute "width" "32" ]
                    [ Svg.path [ Sa.d "M16 2 L16 30 M2 16 L30 16" ] [] ]
                ]
            ]
    else if Array.length model.emotionHistory > 2 then
        nav [ Ha.class "ml-auto" ]
            [ Html.button [ onClick (Route "/graph"), Ha.class "flex items-center justify-center w2 h2 pa1" ]
                [ svg [ Sa.class "w-100 bl bb bw1", fill "white", attribute "stroke" "white", attribute "stroke-width" "8", viewBox "0 0 100 100" ]
                    [ Svg.path [ d "M10 95 L20 90" ]
                        []
                    , Svg.path [ d "M20 90 L30 75" ]
                        []
                    , Svg.path [ d "M30 75 L40 80" ]
                        []
                    , Svg.path [ d "M40 80 L50 55" ]
                        []
                    , Svg.path [ d "M50 55 L60 65" ]
                        []
                    , Svg.path [ d "M60 65 L70 35" ]
                        []
                    , Svg.path [ d "M70 35 L80 25" ]
                        []
                    , Svg.path [ d "M80 25 L90 10" ]
                        []
                    ]
                ]
            ]
    else
        nav [ Ha.class "ml-auto" ] []


isNamed model viewFunction =
    case model.confirmedName of
        "" ->
            loginView model

        _ ->
            viewFunction model


chooseView : Model -> Html Msg
chooseView model =
    case model.location of
        "/" ->
            isNamed model emotionView

        "/mood" ->
            isNamed model emotionView

        "/graph" ->
            isNamed model graphView

        _ ->
            div [] [ Html.text "you're not supposed to be here" ]


loginView : Model -> Html Msg
loginView model =
    div []
        [ h1 [ Ha.class "lh-solid tc" ] [ Html.text "Welcome to rounded" ]
        , p [ Ha.class "mt2 tc" ] [ Html.text "A way for you to keep track of variations in your mood." ]
        , p [ Ha.class "mt2 tc" ] [ Html.text "We recommend inputting once a day to get the best use out of rounded." ]
        , p [ Ha.class "mt2 tc" ] [ Html.text "Enter your name to continue:" ]
        , Html.form [ onSubmit LoginSubmit, Ha.class "flex flex-column items-center justify-center flex-auto mt3" ]
            [ label [ for "name", Ha.class "vh" ]
                [ Html.text "Name" ]
            , input [ Ha.id "name", placeholder "Name", Ha.type_ "text", value model.name, onInput Name, Ha.class "db w-100 center pa2 bn" ]
                []
            , button [ Ha.type_ "submit", Ha.class "grow bn ph3 pv2 white bg-blue db w-100 center mt3" ]
                [ Html.text "Go" ]
            ]
        ]


emotionView : Model -> Html Msg
emotionView model =
    div [ Ha.class "h-100 flex flex-column" ]
        [ p [] [ Html.text <| emotionViewPrompt model ]
        , Html.form [ Ha.class "flex flex-column mt2 flex-1", onSubmit (emotionRouting model) ]
            [ div [ Ha.class "flex flex-1" ]
                [ label [ Ha.class "vh", for "mood" ]
                    [ Html.text "Mood" ]
                , div [ Ha.class "relative flex flex-1 flex-column items-stretch" ]
                    [ div [ Ha.class "pa2 white bg-gray tc br2" ]
                        [ Html.text "Good" ]
                    , div [ Ha.class "flex-1 vh-40" ]
                        [ input [ Ha.class "vertical-slider", Ha.id "mood", Ha.max "10", Ha.min "0", Ha.step "0.1", Ha.type_ "range", value model.current.mood, onInput Mood ]
                            []
                        ]
                    , div [ Ha.class "pa2 white bg-gray tc br2" ]
                        [ Html.text "Bad" ]
                    ]
                , label [ Ha.class "vh", for "energy" ]
                    [ Html.text "Energy" ]
                , div [ Ha.class "relative flex flex-1 flex-column items-stretch ml4" ]
                    [ div [ Ha.class "pa2 white bg-gray tc br2" ]
                        [ Html.text "Energetic" ]
                    , div [ Ha.class "flex-1 vh-40" ]
                        [ input [ Ha.class "vertical-slider", Ha.id "energy", Ha.max "10", Ha.min "0", Ha.step "0.1", Ha.type_ "range", value model.current.energy, onInput Energy ]
                            []
                        ]
                    , div [ Ha.class "pa2 white bg-gray tc br2" ]
                        [ Html.text "Exhausted" ]
                    ]
                ]
            , button [ Ha.class "grow bn mt2 ph3 pv2 white bg-blue db w-100", Ha.type_ "submit" ]
                [ Html.text "Submit" ]
            ]
        ]


emotionRouting : Model -> Msg
emotionRouting model =
    case Array.length model.emotionHistory of
        0 ->
            EmotionToEmotion

        1 ->
            EmotionToEmotion

        _ ->
            EmotionToGraph


emotionViewPrompt : Model -> String
emotionViewPrompt model =
    case Array.length model.emotionHistory of
        0 ->
            "Hi " ++ model.confirmedName ++ ", how were you feeling 2 days ago?"

        1 ->
            "How were you feeling yesterday?"

        _ ->
            "How are you feeling today " ++ model.confirmedName ++ "?"


graphView : Model -> Html Msg
graphView model =
    Html.div []
        [ Html.h2 [ Ha.class "tc" ] [ Html.text ("Here are your results, " ++ model.name ++ "!") ]
        , Html.div [ Ha.class "relative h5 bl bb bw2 b--mid-gray overflow-x-scroll" ]
            [ svg
                [ Sa.class "absolute h-100"
                , viewBox
                    ("0 0 "
                        ++ (Array.length model.emotionHistory
                                |> toString
                           )
                        ++ " 11"
                    )
                , Sa.strokeWidth "0.15"
                ]
                (plotGraph "mood" model.emotionHistory
                    ++ plotGraph "energy" model.emotionHistory
                )
            ]
        ]


plotGraph : String -> Array EmotionDatum -> List (Svg Msg)
plotGraph dataType array =
    let
        emotionType =
            if dataType == "mood" then
                .mood
            else
                .energy
    in
    Array.toList (Array.indexedMap (\i emotion -> graphPoint i (emotionType emotion) array dataType) array)


graphPoint : Int -> String -> Array EmotionDatum -> String -> Svg Msg
graphPoint index y array toPlot =
    let
        dataType =
            if toPlot == "mood" then
                .mood
            else
                .energy

        dataColour =
            if toPlot == "mood" then
                "orange"
            else
                "purple"
    in
    if index == 0 then
        circle
            [ cx (toString index)
            , cy (stringNumMinusNum y 11)
            , r "0.2"
            , Sa.style ("fill: " ++ dataColour ++ "; stroke: " ++ dataColour ++ ";")
            ]
            []
    else
        g []
            [ circle
                [ cx (toString index)
                , cy (stringNumMinusNum y 11)
                , r "0.2"
                , Sa.style ("fill: " ++ dataColour ++ "; stroke: " ++ dataColour ++ ";")
                ]
                []
            , Svg.path
                [ d
                    ("M"
                        ++ toString (index - 1)
                        ++ " "
                        ++ stringNumMinusNum
                            (Array.get (index - 1) array
                                |> getPoint
                                |> dataType
                            )
                            11
                        ++ " L"
                        ++ toString index
                        ++ " "
                        ++ stringNumMinusNum y 11
                    )
                , Sa.style ("stroke: " ++ dataColour)
                ]
                []
            ]


getPoint : Maybe EmotionDatum -> EmotionDatum
getPoint point =
    case point of
        Nothing ->
            { mood = "0", energy = "0" }

        Just val ->
            val


stringNumMinusNum : String -> Int -> String
stringNumMinusNum stringNum num =
    num
        - (String.toInt stringNum |> Result.withDefault 0)
        |> toString


port setStorage : Model -> Cmd msg
