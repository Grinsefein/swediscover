package main

import (
"encoding/binary"
"errors"
)

// Einfacher GTFS-RT Protobuf Parser ohne externe Dependencies
// Implementiert Wire-Type Parsing direkt

// Alert enthält Informationen über Störungen
type Alert struct {
InformedEntity     []*EntitySelector
Cause              *int32
Effect             *int32
Url                *TranslatedString
HeaderText         *TranslatedString
DescriptionText    *TranslatedString
ActivePeriod       []*TimeRange
}

// EntitySelector identifiziert betroffene Entities
type EntitySelector struct {
AgencyId   *string
RouteId    *string
RouteType  *int32
StopId     *string
TripId     *string
DirectionId *int32
}

// TranslatedString enthält Text in mehreren Sprachen
type TranslatedString struct {
Translation []*Translation
}

// Translation ist eine einzelnde Übersetzung
type Translation struct {
Text     *string
Language *string
}

// TimeRange definiert einen Zeitraum
type TimeRange struct {
Start *uint64
End   *uint64
}

// FeedEntity repräsentiert eine einzelne Entität im Feed
type FeedEntity struct {
Id    *string
Alert *Alert
}

// FeedHeader enthält Metadaten über den Feed
type FeedHeader struct {
GtfsRealtimeVersion *string
Timestamp           *uint64
}

// FeedMessage ist die Root-Nachricht für GTFS-RT Feeds
type FeedMessage struct {
Header *FeedHeader
Entity []*FeedEntity
}

// Protobuf Wire Types
const (
WireVarint          = 0
WireFixed64         = 1
WireLengthDelimited = 2
WireFixed32         = 5
)

// ParseFeedMessage parst GTFS-RT Protobuf Daten
func ParseFeedMessage(data []byte) (*FeedMessage, error) {
feed := &FeedMessage{}

for len(data) > 0 {
key, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]

fieldNum := key >> 3
wireType := key & 0x7

switch fieldNum {
case 1: // header
if wireType != WireLengthDelimited {
return nil, errors.New("wrong wire type for header")
}
length, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(length) {
break
}
headerData := data[:length]
data = data[length:]

feed.Header = &FeedHeader{}
for len(headerData) > 0 {
hKey, n := binary.Uvarint(headerData)
if n <= 0 {
break
}
headerData = headerData[n:]

hFieldNum := hKey >> 3
hWireType := hKey & 0x7

if hFieldNum == 1 { // gtfs_realtime_version
if hWireType != WireLengthDelimited {
break
}
strLen, n := binary.Uvarint(headerData)
if n <= 0 {
break
}
headerData = headerData[n:]
if len(headerData) < int(strLen) {
break
}
versionStr := string(headerData[:strLen])
feed.Header.GtfsRealtimeVersion = &versionStr
headerData = headerData[strLen:]
} else if hFieldNum == 3 { // timestamp
if hWireType != WireVarint {
break
}
timestamp, n := binary.Uvarint(headerData)
if n <= 0 {
break
}
headerData = headerData[n:]
feed.Header.Timestamp = &timestamp
} else {
// Skip unknown fields
skipLen := skipField(headerData, hWireType)
if skipLen > 0 && skipLen <= len(headerData) {
headerData = headerData[skipLen:]
} else {
break
}
}
}

case 2: // entity
if wireType != WireLengthDelimited {
return nil, errors.New("wrong wire type for entity")
}
length, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(length) {
break
}
entityData := data[:length]
data = data[length:]

entity := &FeedEntity{}
for len(entityData) > 0 {
eKey, n := binary.Uvarint(entityData)
if n <= 0 {
break
}
entityData = entityData[n:]

eFieldNum := eKey >> 3
eWireType := eKey & 0x7

if eFieldNum == 1 { // id
if eWireType != WireLengthDelimited {
break
}
strLen, n := binary.Uvarint(entityData)
if n <= 0 {
break
}
entityData = entityData[n:]
if len(entityData) < int(strLen) {
break
}
idStr := string(entityData[:strLen])
entity.Id = &idStr
entityData = entityData[strLen:]
} else if eFieldNum == 3 { // alert
if eWireType != WireLengthDelimited {
break
}
alertLen, n := binary.Uvarint(entityData)
if n <= 0 {
break
}
entityData = entityData[n:]
if len(entityData) < int(alertLen) {
break
}
alertData := entityData[:alertLen]
entityData = entityData[alertLen:]

entity.Alert = parseAlert(alertData)
} else {
// Skip unknown fields
skipLen := skipField(entityData, eWireType)
if skipLen > 0 && skipLen <= len(entityData) {
entityData = entityData[skipLen:]
} else {
break
}
}
}

if entity.Alert != nil || entity.Id != nil {
feed.Entity = append(feed.Entity, entity)
}
}
}

return feed, nil
}

func parseAlert(data []byte) *Alert {
alert := &Alert{}

for len(data) > 0 {
key, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]

fieldNum := key >> 3
wireType := key & 0x7

switch fieldNum {
case 1: // informed_entity
if wireType != WireLengthDelimited {
break
}
entLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(entLen) {
break
}
entData := data[:entLen]
data = data[entLen:]

entity := parseEntitySelector(entData)
if entity != nil {
alert.InformedEntity = append(alert.InformedEntity, entity)
}

case 2: // cause
if wireType != WireVarint {
break
}
cause, n := binary.Varint(data)
if n <= 0 {
break
}
data = data[n:]
causeInt32 := int32(cause)
alert.Cause = &causeInt32

case 3: // effect
if wireType != WireVarint {
break
}
effect, n := binary.Varint(data)
if n <= 0 {
break
}
data = data[n:]
effectInt32 := int32(effect)
alert.Effect = &effectInt32

case 4: // url
if wireType != WireLengthDelimited {
break
}
tsLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(tsLen) {
break
}
tsData := data[:tsLen]
data = data[tsLen:]
alert.Url = parseTranslatedString(tsData)

case 5: // header_text
if wireType != WireLengthDelimited {
break
}
tsLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(tsLen) {
break
}
tsData := data[:tsLen]
data = data[tsLen:]
alert.HeaderText = parseTranslatedString(tsData)

case 6: // description_text
if wireType != WireLengthDelimited {
break
}
tsLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(tsLen) {
break
}
tsData := data[:tsLen]
data = data[tsLen:]
alert.DescriptionText = parseTranslatedString(tsData)

case 10: // active_period
if wireType != WireLengthDelimited {
break
}
periodLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(periodLen) {
break
}
periodData := data[:periodLen]
data = data[periodLen:]

period := parseTimeRange(periodData)
if period != nil {
alert.ActivePeriod = append(alert.ActivePeriod, period)
}
}
}

return alert
}

func parseEntitySelector(data []byte) *EntitySelector {
entity := &EntitySelector{}

for len(data) > 0 {
key, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]

fieldNum := key >> 3
wireType := key & 0x7

switch fieldNum {
case 1: // agency_id
if wireType != WireLengthDelimited {
break
}
strLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(strLen) {
break
}
agencyId := string(data[:strLen])
entity.AgencyId = &agencyId
data = data[strLen:]

case 2: // route_id
if wireType != WireLengthDelimited {
break
}
strLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(strLen) {
break
}
routeId := string(data[:strLen])
entity.RouteId = &routeId
data = data[strLen:]

case 3: // route_type
if wireType != WireVarint {
break
}
rt, n := binary.Varint(data)
if n <= 0 {
break
}
data = data[n:]
rtInt32 := int32(rt)
entity.RouteType = &rtInt32

case 4: // stop_id
if wireType != WireLengthDelimited {
break
}
strLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(strLen) {
break
}
stopId := string(data[:strLen])
entity.StopId = &stopId
data = data[strLen:]

case 5: // trip_id
if wireType != WireLengthDelimited {
break
}
strLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(strLen) {
break
}
tripId := string(data[:strLen])
entity.TripId = &tripId
data = data[strLen:]

case 6: // direction_id
if wireType != WireVarint {
break
}
dir, n := binary.Varint(data)
if n <= 0 {
break
}
data = data[n:]
dirInt32 := int32(dir)
entity.DirectionId = &dirInt32
}
}

return entity
}

func parseTranslatedString(data []byte) *TranslatedString {
ts := &TranslatedString{}

for len(data) > 0 {
key, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]

fieldNum := key >> 3
wireType := key & 0x7

if fieldNum == 1 && wireType == WireLengthDelimited { // translation
transLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(transLen) {
break
}
transData := data[:transLen]
data = data[transLen:]

translation := parseTranslation(transData)
if translation != nil {
ts.Translation = append(ts.Translation, translation)
}
} else {
skipLen := skipField(data, wireType)
if skipLen > 0 && skipLen <= len(data) {
data = data[skipLen:]
} else {
break
}
}
}

return ts
}

func parseTranslation(data []byte) *Translation {
trans := &Translation{}

for len(data) > 0 {
key, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]

fieldNum := key >> 3
wireType := key & 0x7

if fieldNum == 1 && wireType == WireLengthDelimited { // text
strLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(strLen) {
break
}
text := string(data[:strLen])
trans.Text = &text
data = data[strLen:]
} else if fieldNum == 2 && wireType == WireLengthDelimited { // language
strLen, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
if len(data) < int(strLen) {
break
}
language := string(data[:strLen])
trans.Language = &language
data = data[strLen:]
} else {
skipLen := skipField(data, wireType)
if skipLen > 0 && skipLen <= len(data) {
data = data[skipLen:]
} else {
break
}
}
}

return trans
}

func parseTimeRange(data []byte) *TimeRange {
period := &TimeRange{}

for len(data) > 0 {
key, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]

fieldNum := key >> 3
wireType := key & 0x7

if fieldNum == 1 && wireType == WireVarint { // start
start, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
period.Start = &start
} else if fieldNum == 2 && wireType == WireVarint { // end
end, n := binary.Uvarint(data)
if n <= 0 {
break
}
data = data[n:]
period.End = &end
} else {
skipLen := skipField(data, wireType)
if skipLen > 0 && skipLen <= len(data) {
data = data[skipLen:]
} else {
break
}
}
}

return period
}

func skipField(data []byte, wireType uint64) int {
switch wireType {
case WireVarint:
for i := 0; i < len(data); i++ {
if data[i]&0x80 == 0 {
return i + 1
}
}
case WireFixed64:
return 8
case WireLengthDelimited:
length, n := binary.Uvarint(data)
if n <= 0 {
return 0
}
return n + int(length)
case WireFixed32:
return 4
}
return 0
}
