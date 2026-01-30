@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Connections'

define view entity ZI_C_Connection as select from /dmo/connection
{
  key carrier_id as CarrierId,
  key connection_id as ConnectionId,
  airport_from_id as AirportFromId,
  airport_to_id as AirportToId,
  departure_time as DepartureTime,
  arrival_time as ArrivalTime,
  distance as Distance,
  distance_unit as DistanceUnit
}
