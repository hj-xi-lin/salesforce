public class closeQuoteRejected  {
    
    public Quote quote {get;set;}    
    public Opportunity opportunity {get;set;}
    public Account account {get;set;}
 
   

    public closeQuoteRejected(ApexPages.StandardController controller) 
    {
        quote     = (Quote) controller.getRecord(); 
        quote = [Select OpportunityId, Opportunity.plLossReason__c, Account.Type,Account.plPlannedHires__c,Account.txtContactsSalutation__c,
                 Account.Contact_First_Name__c, Account.Contact_Last_Name__c,Account.Contact_Email__c from Quote where id=:quote.Id];
      
        opportunity   = new Opportunity();
        opportunity.AccountID         = quote.AccountId;
        opportunity.ID        = quote.OpportunityId;

    
    }
    
    
    public void save()
    {
        saveComplete();
        quote.Status = 'Rejected'; 
   
        update quote.Account;
        update quote.Opportunity;
             update quote;
        
        
 }
  
   
    
    
    public PageReference saveComplete()
    {
        
        return new PageReference('/'+quote.Id);
        
    }
}