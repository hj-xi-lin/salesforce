/*
 *      @author Arun Kumar
 *      @date   25-May-2023
 *      @description   Class to process the Recruiter based Marketing and Sales trigger events
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */
public class MSTEventProcessor {
    public class PayloadInput {
        @InvocableVariable(required=true description='Payload received from BE system')
        public String eventInput;
    }
    
    public class PayloadResult {
        @InvocableVariable
        public String recruiterUid;
        @InvocableVariable
        public String recruiterEmail;
        @InvocableVariable
        public String event;
        @InvocableVariable
        public Datetime timestamp;
    }
    
    /**
    @Methodname     : processPayload
    @Param          : List<PayloadInput>
    @Return         : List<PayloadResult>
    @Description    : To process the payload and return individualized attributes
    **/
    @InvocableMethod(label='Process MST Events' description='Processes the JSON payload and retrieves the attributes.')
    public static List<PayloadResult> processPayload (List<PayloadInput> jsonPayloads) {
        List<PayloadResult> results = new List<PayloadResult>();
        String inputPayload = jsonPayloads.get(0).eventInput;
        
        PayloadResult result = new PayloadResult();
        // Deserialize the JSON payload
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(inputPayload);
        
        // Extract the attributes from the payload
        result.recruiterUid = String.valueOf(payloadMap.get('recruiter_uid'));
        result.recruiterEmail = String.valueOf(payloadMap.get('recruiter_email'));
        result.event = String.valueOf(payloadMap.get('event'));
        result.timestamp = parseDateTime(String.valueOf(payloadMap.get('timestamp')));
        System.debug('Timestamp Processed -->'+result.timestamp);
        results.add(result);
        System.debug('Output -->'+result);
        return results;
    }
    
    /**
    @Methodname     : parseDateTime
    @Param          : String
    @Return         : datetime
    @Description    : To convert the string format "YYYY-MM-DD/THH:MM:SS.XXX/Z" to datetime
    **/
    public static datetime parseDateTime(String eventTimestamp){
        
        List<String> DateAndTimeList = eventTimestamp.split('T');
        List<String> dayList = DateAndTimeList[0].split('-'); 
        List<string> timeList = DateAndTimeList[1].split(':');
        DateTime dt = DateTime.newInstanceGmt(Integer.valueOf(dayList[0]), Integer.valueOf(dayList[1]), Integer.valueOf(dayList[2]), Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]), Integer.valueOf(timeList[2].split('\\.')[0]));
        
        return dt;
    }
}