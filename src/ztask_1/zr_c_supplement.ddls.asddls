@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplements'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_C_Supplement as select from ZI_C_Supplement1
//association [1..1] to /dmo/booking as _Bookings on $projection.BookingId = _Bookings.booking_id
{
  key SupplementId, 
  key BookingId,
  key BookingSupplementId,
  case when instr(SupplementId, 'BV') > 0 then 'Beverage'
            when instr(SupplementId, 'ML') > 0 then 'Meal'
            when instr(SupplementId, 'LU') > 0 then 'Luggage'
            when instr(SupplementId, 'EX') > 0 then 'Extra'
            else ''
            end as SupplementCategory
  // _Bookings
}
