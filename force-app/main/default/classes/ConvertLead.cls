public with sharing class ConvertLead {
    
    public Lead lead {get;set;}    
  
 
    public ConvertLead (ApexPages.StandardController controller) 
    {
        lead     = (Lead) controller.getRecord(); 
        lead = [Select Category_1__c,Category_2__c,Category_3__c,Demo_Date__c,
                 LeadSource,  Status,
                Address,City,Country,PostalCode,Street,NumberOfEmployees,urlCareerPage__c  from Lead where id=:lead.Id];
        
                    
     
    }
    
    
    public PageReference save()
    {
         update lead;
        
         Database.LeadConvert lc = new database.LeadConvert();
         lc.setLeadId(lead.id);
            
         LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
         lc.setConvertedStatus(convertStatus.MasterLabel);
            
         Database.LeadConvertResult lcr = Database.convertLead(lc);
         System.assert(lcr.isSuccess());
        
         return new PageReference('/'+lead.id);
 

     
        
     }
  
   
    
    
   
}