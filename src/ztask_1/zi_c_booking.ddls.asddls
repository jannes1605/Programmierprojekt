@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Booking'

@UI.headerInfo: { typeName:'Booking', typeNamePlural: 'Bookings', title: {type: #STANDARD, value: 'BookingId'}, description: {type: #STANDARD, value: 'TravelId'}}


define view entity ZI_C_BOOKING
  as select from /dmo/booking
  association [0..1] to /dmo/booksuppl_m as _Supplements on  $projection.TravelId    = _Supplements.travel_id
                                                         and $projection.BookingId = _Supplements.booking_id
{
  key travel_id                  as TravelId,
  key booking_id                 as BookingId,

      booking_date               as BookingDate,
      customer_id                as CustomerId,
      carrier_id                 as CarrierId,
      connection_id              as ConnectionId,
      flight_date                as FlightDate,
      flight_price               as FlightPrice,
      currency_code              as CurrencyCode,
      _Supplements.supplement_id as SupplementId
}
