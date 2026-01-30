@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Customer Value Help'

@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_C_CustomerVH
  as select from /dmo/customer

{
  key customer_id as CustomerId,
      first_name  as FirstName,
      last_name   as LastName
}
