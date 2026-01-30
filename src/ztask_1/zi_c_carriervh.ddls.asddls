@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Carrier Id Value Help'

@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_C_CarrierVH
  as select from /dmo/carrier

{
  key carrier_id as CarrierId,

      name       as AirlineName
}
