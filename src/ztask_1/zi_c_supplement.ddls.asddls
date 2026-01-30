@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplements'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_C_Supplement as select from /dmo/suppl_text
{
  key supplement_id     as SupplementId,
  description as Description 
  
}
