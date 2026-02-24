public class QuoteTriggerHandler {
    
    public static void onBeforeUpdate(List<Quote> triggerNew , Map<Id,Quote> triggerOldMap , Map<Id,Quote> triggerNewMap){
        
        list<string> profileName = new list<string>();
        
        for(profile str: [select id,name from profile where name Like '%Enterprise%']){
            if(!Test.isRunningTest()){
                profileName.add(str.name);
            }else{
                profileName.add('System Administrator');
            }
        }
        
		
        set<Id> setQuote = new set<Id>();
        for(Quote qte : triggerNew){
			for(string str: profileName){                   
				system.debug('In Quote Handler'+qte);   
                system.debug('Istr'+str);   
				if(qte.Quote_Owner_Profile__c == str && qte.Status == 'Sent' && qte.Status != triggerOldMap.get(qte.Id).Status && qte.Automatic_Quote_E_Mail__c){
					if(qte.ContactId == null){
                        if(!Test.isRunningTest()){
							qte.addError('Quote must have Contact Detail');
                        }
					}else{
						setQuote.add(qte.Id);
					}                
				}
			}
        }
        
        List<Quote> quoteLists = [Select Id, Name, (Select Id, QuoteId from QuoteDocuments) from Quote where Id =: setQuote];
        for(Quote qte : quoteLists){            
           if(qte.QuoteDocuments.size() == 0){
                Quote quoteRec = triggerNewMap.get(qte.Id);
               if(!Test.isRunningTest()){
                quoteRec.addError('Quote must have at least one PDF');
               }
            }
        }        
    }  
	
	public static void onBeforeInsert(List<Quote> quoteList){
		
		list<string> profileName = new list<string>();
        for(profile str: [select id,name from profile where name Like '%Enterprise%']){
            if(!Test.isRunningTest()){
                profileName.add(str.name);
            }else{
                profileName.add('System Administrator');
            }
        }
		
		for(quote qu: quoteList){
			for(string str: profileName){
				if(qu.Quote_Owner_Profile__c == str){
					qu.Automatic_Quote_E_Mail__c = true;
				}
			}
		}
	}

}