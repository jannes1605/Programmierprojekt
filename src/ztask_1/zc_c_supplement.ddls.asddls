@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Suppl'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_C_Supplement as select from ZR_C_Supplement
{
  key SupplementId, 
  key BookingId,
  key BookingSupplementId,
  SupplementCategory
}
