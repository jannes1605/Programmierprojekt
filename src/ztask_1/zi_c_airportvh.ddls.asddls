@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Airport Id Value Help'

@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_C_AirportVH
  as select from /dmo/airport

{
  key airport_id as AirportId,

      name       as Name
}
