--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- This Source Code Form is subject to the terms of the Mozilla Public        --
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,  --
-- you can obtain one at http://mozilla.org/MPL/2.0/.                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


module Polyline3d exposing
    ( Polyline3d
    , fromVertices, on
    , vertices, segments, length, boundingBox, centroid
    , scaleAbout, rotateAround, translateBy, translateIn, mirrorAcross, projectOnto, mapVertices
    , relativeTo, placeIn, projectInto
    )

{-| A `Polyline3d` represents a sequence of vertices in 3D connected by line
segments. This module contains a variety of polyline-related functionality, such
as

  - Computing the length of polylines
  - Scaling, rotating, translating and mirroring polylines
  - Converting polylines between different coordinate systems

@docs Polyline3d


# Constructors

@docs fromVertices, on


# Properties

@docs vertices, segments, length, boundingBox, centroid


# Transformations

Transforming a polyline is equivalent to transforming each of its vertices.

@docs scaleAbout, rotateAround, translateBy, translateIn, mirrorAcross, projectOnto, mapVertices


# Coordinate conversions

@docs relativeTo, placeIn, projectInto

-}

import Angle exposing (Angle)
import Axis3d exposing (Axis3d)
import BoundingBox3d exposing (BoundingBox3d)
import Direction3d exposing (Direction3d)
import Frame3d exposing (Frame3d)
import Geometry.Types as Types
import LineSegment3d exposing (LineSegment3d)
import Plane3d exposing (Plane3d)
import Point3d exposing (Point3d)
import Polyline2d exposing (Polyline2d)
import Quantity exposing (Quantity)
import Quantity.Extra as Quantity
import SketchPlane3d exposing (SketchPlane3d)
import Vector3d exposing (Vector3d)


{-| -}
type alias Polyline3d units coordinates =
    Types.Polyline3d units coordinates


{-| Construct a polyline from its vertices:

    examplePolyline =
        Polyline3d.fromVertices
            [ Point3d.meters 0 0 0
            , Point3d.meters 1 0 0
            , Point3d.meters 1 2 0
            , Point3d.meters 1 2 3
            ]

-}
fromVertices : List (Point3d units coordinates) -> Polyline3d units coordinates
fromVertices givenVertices =
    Types.Polyline3d givenVertices


{-| Construct a 3D polyline lying _on_ a sketch plane by providing a 2D polyline
specified in XY coordinates _within_ the sketch plane.

    Polyline3d.on SketchPlane3d.yz <|
        Polyline2d.fromVertices
            [ Point2d.meters 0 0
            , Point2d.meters 1 0
            , Point2d.meters 1 1
            , Point2d.meters 2 1
            ]
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters 0 0 0
    -->     , Point3d.meters 0 1 0
    -->     , Point3d.meters 0 1 1
    -->     , Point3d.meters 0 2 1
    -->     ]

-}
on : SketchPlane3d units coordinates3d { defines : coordinates2d } -> Polyline2d units coordinates2d -> Polyline3d units coordinates3d
on sketchPlane polyline2d =
    Polyline2d.vertices polyline2d
        |> List.map (Point3d.on sketchPlane)
        |> fromVertices


{-| Get the vertices of a polyline.

    Polyline3d.vertices examplePolyline
    --> [ Point3d.meters 0 0 0
    --> , Point3d.meters 1 0 0
    --> , Point3d.meters 1 2 0
    --> , Point3d.meters 1 2 3
    --> ]

-}
vertices : Polyline3d units coordinates -> List (Point3d units coordinates)
vertices (Types.Polyline3d polylineVertices) =
    polylineVertices


{-| Get the individual segments of a polyline.

    Polyline3d.segments examplePolyline
    --> [ LineSegment3d.fromEndpoints
    -->     ( Point3d.meters 0 0 0
    -->     , Point3d.meters 1 0 0
    -->     )
    --> , LineSegment3d.fromEndpoints
    -->     ( Point3d.meters 1 0 0
    -->     , Point3d.meters 1 2 0
    -->     )
    --> , LineSegment3d.fromEndpoints
    -->     ( Point3d.meters 1 2 0
    -->     , Point3d.meters 1 2 3
    -->     )
    --> ]

-}
segments : Polyline3d units coordinates -> List (LineSegment3d units coordinates)
segments polyline =
    case vertices polyline of
        [] ->
            []

        (first :: rest) as all ->
            List.map2 LineSegment3d.from all rest


{-| Get the overall length of a polyline (the sum of the lengths of its
segments).

    Polyline3d.length examplePolyline
    --> 6

-}
length : Polyline3d units coordinates -> Quantity Float units
length polyline =
    segments polyline |> List.map LineSegment3d.length |> Quantity.sum


{-| Scale a polyline about the given center point by the given scale.

    point =
        Point3d.meters 1 0 0

    Polyline3d.scaleAbout point 2 examplePolyline
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters -1 0 0
    -->     , Point3d.meters 1 0 0
    -->     , Point3d.meters 1 4 0
    -->     , Point3d.meters 1 4 6
    -->     ]

-}
scaleAbout : Point3d units coordinates -> Float -> Polyline3d units coordinates -> Polyline3d units coordinates
scaleAbout point scale polyline =
    mapVertices (Point3d.scaleAbout point scale) polyline


{-| Rotate a polyline around the given axis by the given angle (in radians).

    examplePolyline
        |> Polyline3d.rotateAround Axis3d.z (Angle.degrees 90)
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters 0 0 0
    -->     , Point3d.meters 0 1 0
    -->     , Point3d.meters -2 1 0
    -->     , Point3d.meters -2 1 3
    -->     ]

-}
rotateAround : Axis3d units coordinates -> Angle -> Polyline3d units coordinates -> Polyline3d units coordinates
rotateAround axis angle polyline =
    mapVertices (Point3d.rotateAround axis angle) polyline


{-| Translate a polyline by the given displacement.

    displacement =
        Vector3d.fromComponents ( 1, 2, 3 )

    Polyline3d.translateBy displacement examplePolyline
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters 1 2 3
    -->     , Point3d.meters 2 2 3
    -->     , Point3d.meters 2 4 3
    -->     , Point3d.meters 2 4 6
    -->     ]

-}
translateBy : Vector3d units coordinates -> Polyline3d units coordinates -> Polyline3d units coordinates
translateBy vector polyline =
    mapVertices (Point3d.translateBy vector) polyline


{-| Translate a polyline in a given direction by a given distance;

    Polyline3d.translateIn direction distance

is equivalent to

    Polyline3d.translateBy
        (Vector3d.withLength distance direction)

-}
translateIn : Direction3d coordinates -> Quantity Float units -> Polyline3d units coordinates -> Polyline3d units coordinates
translateIn direction distance polyline =
    translateBy (Vector3d.withLength distance direction) polyline


{-| Mirror a polyline across the given plane.

    Polyline3d.mirrorAcross Plane3d.xz examplePolyline
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters 0 0 0
    -->     , Point3d.meters 1 0 0
    -->     , Point3d.meters 1 -2 0
    -->     , Point3d.meters 1 -2 3
    -->     ]

-}
mirrorAcross : Plane3d units coordinates -> Polyline3d units coordinates -> Polyline3d units coordinates
mirrorAcross plane polyline =
    mapVertices (Point3d.mirrorAcross plane) polyline


{-| Find the [orthographic projection](https://en.wikipedia.org/wiki/Orthographic_projection)
of a polyline onto a plane. This will flatten the polyline.

    Polyline3d.projectOnto Plane3d.xz examplePolyline
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters 0 0 0
    -->     , Point3d.meters 1 0 0
    -->     , Point3d.meters 1 0 0
    -->     , Point3d.meters 1 0 3
    -->     ]

-}
projectOnto : Plane3d units coordinates -> Polyline3d units coordinates -> Polyline3d units coordinates
projectOnto plane polyline =
    mapVertices (Point3d.projectOnto plane) polyline


{-| Transform each vertex of a polyline by the given function. All other
transformations can be defined in terms of `mapVertices`; for example,

    Polyline3d.mirrorAcross plane

is equivalent to

    Polyline3d.mapVertices (Point3d.mirrorAcross plane)

-}
mapVertices : (Point3d units1 coordinates1 -> Point3d units2 coordinates2) -> Polyline3d units1 coordinates1 -> Polyline3d units2 coordinates2
mapVertices function polyline =
    vertices polyline |> List.map function |> fromVertices


{-| Take a polyline defined in global coordinates, and return it expressed
in local coordinates relative to a given reference frame.

    localFrame =
        Frame3d.atPoint
            (Point3d.meters 1 2 3)

    Polyline3d.relativeTo localFrame examplePolyline
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters -1 -2 -3
    -->     , Point3d.meters 0 -2 -3
    -->     , Point3d.meters 0 0 -3
    -->     , Point3d.meters 0 0 0
    -->     ]

-}
relativeTo : Frame3d units globalCoordinates { defines : localCoordinates } -> Polyline3d units globalCoordinates -> Polyline3d units localCoordinates
relativeTo frame polyline =
    mapVertices (Point3d.relativeTo frame) polyline


{-| Take a polyline considered to be defined in local coordinates relative
to a given reference frame, and return that polyline expressed in global
coordinates.

    localFrame =
        Frame3d.atPoint
            (Point3d.meters 1 2 3)

    Polyline3d.placeIn localFrame examplePolyline
    --> Polyline3d.fromVertices
    -->     [ Point3d.meters 1 2 3
    -->     , Point3d.meters 2 2 3
    -->     , Point3d.meters 2 4 3
    -->     , Point3d.meters 2 4 6
    -->     ]

-}
placeIn : Frame3d units globalCoordinates { defines : localCoordinates } -> Polyline3d units localCoordinates -> Polyline3d units globalCoordinates
placeIn frame polyline =
    mapVertices (Point3d.placeIn frame) polyline


{-| Project a polyline into a given sketch plane. Conceptually, this finds the
[orthographic projection](https://en.wikipedia.org/wiki/Orthographic_projection)
of the polyline onto the plane and then expresses the projected polyline in 2D
sketch coordinates.

    Polyline3d.projectInto Plane3d.xy examplePolyline
    --> Polyline2d.fromVertices
    -->     [ Point2d.meters 0 0
    -->     , Point2d.meters 1 0
    -->     , Point2d.meters 1 2
    -->     , Point2d.meters 1 2
    -->     ]

-}
projectInto : SketchPlane3d units coordinates3d { defines : coordinates2d } -> Polyline3d units coordinates3d -> Polyline2d units coordinates2d
projectInto sketchPlane polyline =
    vertices polyline
        |> List.map (Point3d.projectInto sketchPlane)
        |> Polyline2d.fromVertices


{-| Get the minimal bounding box containing a given polyline. Returns `Nothing`
if the polyline has no vertices.

    Polyline3d.boundingBox examplePolyline
    --> Just
    -->     (BoundingBox3d.fromExtrema
    -->         { minX = 0
    -->         , maxX = 1
    -->         , minY = 0
    -->         , maxY = 2
    -->         , minZ = 0
    -->         , maxZ = 3
    -->         }
    -->     )

-}
boundingBox : Polyline3d units coordinates -> Maybe (BoundingBox3d units coordinates)
boundingBox polyline =
    Point3d.hullN (vertices polyline)


{-| Find the centroid (center of mass) of a polyline. Returns `Nothing` if the
polyline has no vertices.

    Polyline3d.centroid examplePolyline
    --> Just (Point3d.meters 0.9167 1.333 0.75)

-}
centroid : Polyline3d units coordinates -> Maybe (Point3d units coordinates)
centroid polyline =
    case ( vertices polyline, boundingBox polyline ) of
        ( [], _ ) ->
            Nothing

        ( _, Nothing ) ->
            Nothing

        ( first :: _, Just box ) ->
            let
                polylineLength =
                    length polyline
            in
            if polylineLength == Quantity.zero then
                Just first

            else
                let
                    roughCentroid =
                        BoundingBox3d.centerPoint box

                    helper =
                        refineBySegment polylineLength roughCentroid
                in
                segments polyline
                    |> List.foldl helper roughCentroid
                    |> Just


refineBySegment : Quantity Float units -> Point3d units coordinates -> LineSegment3d units coordinates -> Point3d units coordinates -> Point3d units coordinates
refineBySegment polylineLength roughCentroid segment currentCentroid =
    let
        segmentMidpoint =
            LineSegment3d.midpoint segment

        segmentLength =
            LineSegment3d.length segment
    in
    Vector3d.from roughCentroid segmentMidpoint
        |> Vector3d.scaleBy (Quantity.ratio segmentLength polylineLength)
        |> (\v -> Point3d.translateBy v currentCentroid)
