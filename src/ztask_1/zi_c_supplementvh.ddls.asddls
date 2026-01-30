@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplement VH'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_C_SUPPLEMENTVH as select from /dmo/suppl_text
{
  key supplement_id as SupplementId,
  description as Description
  
}
