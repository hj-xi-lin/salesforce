public with sharing class CloseQuote {
    
    public Quote quote {get;set;}    
    public Onboarding__c onboardingObj {get;set;}
    public Account account {get;set;}
    public Attachment attach {get; set;}
    public List<Attachment> fileList {get; set;}
    public Quote c;
   

    public closeQuote(ApexPages.StandardController controller) 
    {
        attach = new Attachment();
        fileList = new List<Attachment>();
        fileList.add(attach);
        quote     = (Quote) controller.getRecord(); 
         quote = [Select OpportunityId,Opportunity.Onboarding__c ,Account.plPlannedHires__c,Account.txtContactsSalutation__c,
                 Account.Contact_First_Name__c, Account.Contact_Last_Name__c,Account.Contact_Email__c from Quote where id=:quote.Id];
        if(quote.Opportunity.Onboarding__c != null){
            
            onboardingObj = [select Account__c,Opportunity__c,Name,Contact__c,txtComments__c from Onboarding__c where Id =:quote.Opportunity.Onboarding__c];
        }else{
            onboardingObj   = new Onboarding__c();
            onboardingObj.Account__c         = quote.AccountId;
            onboardingObj.Opportunity__c        = quote.OpportunityId;
        }

        c = (Quote) controller.getRecord(); 
    }
    
    
    public List<Attachment> getAttachments(){
      if(fileList == null) 
         fileList = new List<Attachment>();
      return fileList; 
    }
     
     public PageReference AddAttachs() {
        fileList.add(new Attachment());
        return null;
      }
     
    
    public PageReference save()
    {
        update quote.Account;
        upsert onboardingObj;
        quote.Opportunity.Onboarding__c  = onboardingObj.Id;
        update quote.Opportunity;
        
        quote.Status = 'Accepted'; 
        update quote;
        
       
        
        uploadAttachment();
        return new PageReference('/'+quote.Id);
    }
    
    public PageReference uploadAttachment() { 
      
          if(quote != null) {            
               List<Attachment> attachments = new List<Attachment>();                               
                      
                for(Attachment att : fileList)              
                { 
                if(att.name != null && att.body != null)
                attachments.add(new Attachment(parentId = quote.OpportunityId, name = att.name, body = att.body)) ;                
                }
                if(attachments != null){
                   upsert attachments;                 
                }          
          }                    
  
      return new PageReference('/'+quote.Id);      
    }   
    
    
}