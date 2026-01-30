@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Suppl'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_C_Supplement1 as select from /dmo/booksuppl_m
{
  key travel_id as TravelId,
  key booking_id as BookingId,
  key booking_supplement_id as BookingSupplementId,
  supplement_id as SupplementId
}
