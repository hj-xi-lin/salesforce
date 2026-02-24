/*
 *      @author Arun Kumar
 *      @date   21-Apr-2023
 *      @description   Class to generate message for HeyPaket
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
public class HeyPaketNotification {
    
    @InvocableMethod(label='Generate HeyPakete Message' description='Generates a message')
    public static List<HeyPaketMessageOutput> generateHeyPaketeMessage(List<HeyPaketMessageInput> heyPaketCustomerId){
        
        Id accountId = heyPaketCustomerId.get(0).accountId;
        
        //Generating message
        String accountUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + accountId;
		String messageText = 'A New HeyPaket of type  ' + heyPaketCustomerId.get(0).paketType + ' has been ' + heyPaketCustomerId.get(0).activationType + ' for the customer';
        
        //Getting customer details
        Account acc = new Account();
        acc = [SELECT Id, Name FROM Account WHERE ID =: accountId];
        
        Map<String, Object> message = new Map<String, Object>();
        message.put('text', messageText);
        List<Map<String, Object>> attachments = new List<Map<String, Object>>();
        Map<String, Object> attachment = new Map<String, Object>();
        List<Map<String, Object>> fields = new List<Map<String, Object>>();
        Map<String, Object> field = new Map<String, Object>();
        //field.put('title', 'Customer Details:');
        field.put('value', '<' + accountUrl + '|'+acc.Name+'>');
        field.put('short', true);
        fields.add(field);
        attachment.put('fields', fields);
        attachments.add(attachment);
        message.put('attachments', attachments);
        
        List<HeyPaketMessageOutput> outputList = new List<HeyPaketMessageOutput>();
        HeyPaketMessageOutput output = new HeyPaketMessageOutput();
        output.message = JSON.serialize(message);
        outputList.add(output);
        
        return outputList;
    }
    
    public class HeyPaketMessageInput{
        @InvocableVariable(required=true description='The record Id of the account')
        public string accountId;
        @InvocableVariable(required=true)
        public String paketType;
        @InvocableVariable(required=true)
        public String activationType;
    }
    
    public class HeyPaketMessageOutput{
        @InvocableVariable
        public string message;
    }

}