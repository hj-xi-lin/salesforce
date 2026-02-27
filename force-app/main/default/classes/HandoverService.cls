/**
 * @description Service class for Handover Wizard functionality
 * Handles field descriptions, Customer_360 record creation, and data updates
 * 
 * SECURITY NOTE: This class intentionally uses "without sharing" because:
 * - Customer_360__c records are created by a Flow (running as automation user),
 *   so the AE user who launches the wizard does not own the record and may lack
 *   sharing access if OWD is Private.
 * - The wizard reads cross-object data (Account, Opportunity, Contact) that the
 *   invoking user may not have full sharing access to via their role hierarchy.
 * - All entry points are @AuraEnabled and require the Handover_Wizard_Access
 *   permission set, which limits who can invoke these methods.
 * If sharing requirements change, consider refactoring elevated-access queries
 * into a dedicated "without sharing" inner helper class.
 * 
 * NOTE: Field API names based on org configuration:
 * - Account.NumberOfEmployees (standard field)
 * - Account.ParentId (standard field)
 * - Account.Ultimate_Parent_Account__c (formula field - read only)
 * - Account.Key_Contact__c (custom lookup to Contact)
 * - Account.Strategical_Key_Contact__c (custom lookup to Contact)
 * - Account.GTM_Motion_Account__c (picklist)
 * - Account.plOpenJobs__c (text/picklist - range values like "20-49")
 * - Account.Estimated_Wallet_Size__c (currency)
 */
public without sharing class HandoverService {
    
    /**
     * @description Get field descriptions (help text) for specified fields
     * @param objectApiName The API name of the object
     * @param fieldApiNames List of field API names
     * @return Map of field API name to help text
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFieldDescriptions(String objectApiName, List<String> fieldApiNames) {
        Map<String, String> fieldDescriptions = new Map<String, String>();
        
        try {
            List<Schema.DescribeSObjectResult> describeResults = Schema.describeSObjects(new List<String>{objectApiName});
            if (describeResults.isEmpty()) {
                return fieldDescriptions;
            }
            
            Map<String, Schema.SObjectField> fieldMap = describeResults[0].fields.getMap();
            
            for (String fieldName : fieldApiNames) {
                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName.toLowerCase()).getDescribe();
                    String helpText = fieldDescribe.getInlineHelpText();
                    fieldDescriptions.put(fieldName, helpText != null ? helpText : '');
                }
            }
        } catch (Exception e) {
            Logger.error('HandoverService.getFieldDescriptions failed for object: ' + objectApiName + '. Error: ' + e.getMessage());
            Logger.saveLog();
        }
        
        return fieldDescriptions;
    }
    
    /**
     * @description Initialize handover wizard - gets context and creates Customer_360 if needed
     * @param taskId The Task record ID
     * @return HandoverContext wrapper with all needed data including Customer_360 Id
     */
    @AuraEnabled
    public static HandoverContext initializeHandover(Id taskId) {
        HandoverContext context = new HandoverContext();
        
        try {
            // Get Task with related data
            Task taskRecord = [
                SELECT Id, Subject, WhatId, OwnerId, What.Name, What.Type
                FROM Task
                WHERE Id = :taskId
                LIMIT 1
            ];
            
            context.taskId = taskRecord.Id;
            
            // Get Account - either directly or through the related Opportunity
            Id accountId = null;
            Schema.SObjectType whatType = taskRecord.WhatId != null ? taskRecord.WhatId.getSObjectType() : null;
            
            if (whatType == Opportunity.SObjectType) {
                Opportunity opp = [
                    SELECT Id, AccountId, CloseDate, Amount, Product_Type__c,
                           Account.Name, Account.Id,
                           Account.NumberOfEmployees,
                           Account.GTM_Motion_Account__c,
                           Account.plOpenJobs__c,
                           Account.Estimated_Wallet_Size__c,
                           Account.ParentId, Account.Parent.Name,
                           Account.Ultimate_Parent_Account__c,
                           Account.Key_Contact__c, Account.Key_Contact__r.FirstName,
                           Account.Key_Contact__r.LastName, Account.Key_Contact__r.Email,
                           Account.Key_Contact__r.Phone, Account.Key_Contact__r.Title,
                           Account.Strategical_Key_Contact__c, 
                           Account.Strategical_Key_Contact__r.FirstName,
                           Account.Strategical_Key_Contact__r.LastName,
                           Account.Strategical_Key_Contact__r.Email,
                           Account.Strategical_Key_Contact__r.Phone,
                           Account.Strategical_Key_Contact__r.Title
                    FROM Opportunity
                    WHERE Id = :taskRecord.WhatId
                    LIMIT 1
                ];
                
                accountId = opp.AccountId;
                context.opportunityId = opp.Id;
                context.accountId = opp.AccountId;
                context.accountName = opp.Account.Name;
                context.accountUrl = '/lightning/r/Account/' + opp.AccountId + '/view';
                context.employees = opp.Account.NumberOfEmployees;
                context.gtmMotion = opp.Account.GTM_Motion_Account__c;
                context.openJobs = opp.Account.plOpenJobs__c;
                context.estimatedWalletSize = opp.Account.Estimated_Wallet_Size__c;
                context.parentAccountId = opp.Account.ParentId;
                context.parentAccountName = opp.Account.Parent?.Name;
                context.ultimateParentAccount = opp.Account.Ultimate_Parent_Account__c;
                
                // Opportunity-specific fields for banner
                context.opportunityCloseDate = opp.CloseDate;
                context.opportunityAmount = opp.Amount;
                context.productSold = opp.Product_Type__c;
                
                populateContactInfo(context, 
                    opp.Account.Strategical_Key_Contact__c, opp.Account.Strategical_Key_Contact__r,
                    opp.Account.Key_Contact__c, opp.Account.Key_Contact__r);
                    
            } else if (whatType == Account.SObjectType) {
                Account acc = [
                    SELECT Id, Name, NumberOfEmployees,
                           GTM_Motion_Account__c,
                           plOpenJobs__c,
                           Estimated_Wallet_Size__c,
                           ParentId, Parent.Name, Ultimate_Parent_Account__c,
                           Key_Contact__c, Key_Contact__r.FirstName, Key_Contact__r.LastName,
                           Key_Contact__r.Email, Key_Contact__r.Phone, Key_Contact__r.Title,
                           Strategical_Key_Contact__c, Strategical_Key_Contact__r.FirstName,
                           Strategical_Key_Contact__r.LastName, Strategical_Key_Contact__r.Email,
                           Strategical_Key_Contact__r.Phone, Strategical_Key_Contact__r.Title
                    FROM Account
                    WHERE Id = :taskRecord.WhatId
                    LIMIT 1
                ];
                
                accountId = acc.Id;
                context.accountId = acc.Id;
                context.accountName = acc.Name;
                context.accountUrl = '/lightning/r/Account/' + acc.Id + '/view';
                context.employees = acc.NumberOfEmployees;
                context.gtmMotion = acc.GTM_Motion_Account__c;
                context.openJobs = acc.plOpenJobs__c;
                context.estimatedWalletSize = acc.Estimated_Wallet_Size__c;
                context.parentAccountId = acc.ParentId;
                context.parentAccountName = acc.Parent?.Name;
                context.ultimateParentAccount = acc.Ultimate_Parent_Account__c;
                
                populateContactInfo(context, 
                    acc.Strategical_Key_Contact__c, acc.Strategical_Key_Contact__r,
                    acc.Key_Contact__c, acc.Key_Contact__r);
            }
            
            // Create or get existing Customer_360__c record for this Account
            if (accountId != null) {
                Customer_360__c c360 = getCustomer360(accountId);
                context.customer360Id = c360.Id;
                
                // Load existing data from Customer_360__c for resume capability
                context.documentationStatus = c360.Documentation_Status__c;
                context.currentWizardStep = c360.Current_Wizard_Step__c;
                context.customerGoals = c360.Customer_Goals__c;
                context.risks = c360.Risks__c;
                context.relationshipRating = c360.Relationship_Rating__c;
                context.relationshipReason = c360.Relationship_Reason__c;
                context.keyLogistics = c360.Key_Logistics__c;
                context.dos = c360.Dos__c;
                context.donts = c360.Donts__c;
                context.other = c360.Other__c;
                context.handoverUrgency = c360.Handover_Urgency__c;
            }
            
        } catch (Exception e) {
            Logger.error('HandoverService.initializeHandover failed for taskId: ' + taskId + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            Logger.saveLog();
            throw new AuraHandledException('Error loading handover data: ' + e.getMessage());
        }
        
        return context;
    }
    
    /**
     * @description Get existing Customer_360__c record for Pilot Handover
     * The record is created by the Flow when Opportunity reaches "Contract Received" stage
     * @param accountId The Account ID
     * @return Customer_360__c record (existing only - throws error if not found)
     */
    private static Customer_360__c getCustomer360(Id accountId) {
        // Check for existing Pilot Handover record (not completed)
        List<Customer_360__c> existing = [
            SELECT Id, Documentation_Status__c, Current_Wizard_Step__c,
                   Customer_Goals__c, Risks__c, Relationship_Rating__c,
                   Relationship_Reason__c, Key_Logistics__c, Dos__c, Donts__c, Other__c,
                   Handover_Urgency__c,
                   Timestamp_Step_PreCheck_Started__c, Timestamp_Step_PreCheck_Completed__c,
                   Timestamp_Step_Notes_Started__c, Timestamp_Step_Notes_Completed__c,
                   Timestamp_Step_Review_Started__c
            FROM Customer_360__c 
            WHERE Account__c = :accountId 
            AND Type__c = 'Pilot Handover'
            AND Documentation_Status__c != 'Completed'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (existing.isEmpty()) {
            // No C360 record found - the Flow should have created one when Opp reached "Contract Received"
            throw new AuraHandledException('Keine Handover-Dokumentation gefunden. Bitte stellen Sie sicher, dass die Opportunity den Status "Contract received" erreicht hat.');
        }
        
        // Update status to In Progress if it was Not Started
        Customer_360__c c360 = existing[0];
        if (c360.Documentation_Status__c == 'Not Started') {
            c360.Documentation_Status__c = 'In Progress';
            c360.Timestamp_Step_PreCheck_Started__c = DateTime.now();
            if (c360.Current_Wizard_Step__c == null) {
                c360.Current_Wizard_Step__c = 'Pre-check';
            }
            try {
                update c360;
            } catch (Exception e) {
                Logger.error('HandoverService.getCustomer360 failed to update existing C360 for accountId: ' + accountId + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
                Logger.saveLog();
                throw e;
            }
        }
        return c360;
    }
    
    /**
     * @description Save handover data and perform related actions
     * Supports delta saves - only updates fields that are present in the dataMap
     * @param dataMap The handover data to save (only changed fields)
     * @return SaveResult with success status and any messages
     */
    @AuraEnabled
    public static SaveResult saveHandoverData(Map<String, Object> dataMap) {
        SaveResult result = new SaveResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            HandoverSaveRequest data = parseDataMap(dataMap);
            
            // IDOR protection: resolve accountId from the taskId (root of trust,
            // supplied by force:hasRecordId), then verify the customer360Id belongs
            // to that same account. This prevents a crafted request from targeting
            // an unrelated account via a foreign customer360Id.
            Id taskIdForAuth = (Id)dataMap.get('taskId');
            Id customer360IdForLookup = (Id)dataMap.get('customer360Id');
            Id accountId = null;
            
            if (taskIdForAuth != null && customer360IdForLookup != null) {
                Task authTask = [SELECT WhatId FROM Task WHERE Id = :taskIdForAuth LIMIT 1];
                Id expectedAccountId = null;
                if (authTask.WhatId != null) {
                    Schema.SObjectType whatType = authTask.WhatId.getSObjectType();
                    if (whatType == Opportunity.SObjectType) {
                        Opportunity authOpp = [SELECT AccountId FROM Opportunity WHERE Id = :authTask.WhatId LIMIT 1];
                        expectedAccountId = authOpp.AccountId;
                    } else if (whatType == Account.SObjectType) {
                        expectedAccountId = authTask.WhatId;
                    }
                }
                
                Customer_360__c c360Lookup = [
                    SELECT Account__c FROM Customer_360__c
                    WHERE Id = :customer360IdForLookup LIMIT 1
                ];
                
                if (expectedAccountId != null && c360Lookup.Account__c != expectedAccountId) {
                    throw new AuraHandledException('Die angegebene Handover-Dokumentation gehört nicht zu dieser Aufgabe.');
                }
                accountId = c360Lookup.Account__c;
            } else if (customer360IdForLookup != null) {
                Customer_360__c c360Lookup = [
                    SELECT Account__c FROM Customer_360__c
                    WHERE Id = :customer360IdForLookup LIMIT 1
                ];
                accountId = c360Lookup.Account__c;
            }
            
            if (accountId != null) {
                Account acc = new Account(Id = accountId);
                Boolean accountNeedsUpdate = false;
                
                // Only update fields that are actually in the dataMap
                if (dataMap.containsKey('employees') && data.employees != null) {
                    acc.NumberOfEmployees = data.employees;
                    accountNeedsUpdate = true;
                }
                
                if (dataMap.containsKey('openJobs') && data.openJobs != null) {
                    acc.plOpenJobs__c = data.openJobs;
                    accountNeedsUpdate = true;
                }
                
                if (dataMap.containsKey('parentAccountId')) {
                    acc.ParentId = data.parentAccountId;
                    accountNeedsUpdate = true;
                }
                
                if (dataMap.containsKey('strategicContactId')) {
                    acc.Strategical_Key_Contact__c = data.strategicContactId;
                    accountNeedsUpdate = true;
                }
                
                if (dataMap.containsKey('operationalContactId')) {
                    acc.Key_Contact__c = data.operationalContactId;
                    accountNeedsUpdate = true;
                }
                
                if (accountNeedsUpdate) {
                    try {
                        update acc;
                    } catch (Exception e) {
                        Logger.error('HandoverService.saveHandoverData failed to update Account for accountId: ' + accountId + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
                        Logger.saveLog();
                        throw e;
                    }
                }
            }
            
            // Update Customer_360__c record - only fields present in the request
            if (customer360IdForLookup != null) {
                Customer_360__c c360 = new Customer_360__c(Id = customer360IdForLookup);
                Boolean c360NeedsUpdate = false;
                
                // Notes fields - only update if present in dataMap
                if (dataMap.containsKey('customerGoals')) {
                    c360.Customer_Goals__c = data.customerGoals;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('risks')) {
                    c360.Risks__c = data.risks;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('relationshipRating')) {
                    c360.Relationship_Rating__c = data.relationshipRating;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('relationshipReason')) {
                    c360.Relationship_Reason__c = data.relationshipReason;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('keyLogistics')) {
                    c360.Key_Logistics__c = data.keyLogistics;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('dos')) {
                    c360.Dos__c = data.dos;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('donts')) {
                    c360.Donts__c = data.donts;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('other')) {
                    c360.Other__c = data.other;
                    c360NeedsUpdate = true;
                }
                if (dataMap.containsKey('handoverUrgency')) {
                    c360.Handover_Urgency__c = data.handoverUrgency;
                    c360NeedsUpdate = true;
                }
                
                // Documentation status - always update if present
                if (dataMap.containsKey('documentationStatus') && data.documentationStatus != null) {
                    c360.Documentation_Status__c = data.documentationStatus;
                    c360NeedsUpdate = true;
                }
                
                // Update current step and track timestamps for step transitions
                if (data.currentWizardStep != null) {
                    c360.Current_Wizard_Step__c = data.currentWizardStep;
                    c360NeedsUpdate = true;
                    
                    // Track step completion/start timestamps
                    DateTime now = DateTime.now();
                    if (data.previousWizardStep == 'Pre-check' && data.currentWizardStep == 'Notes') {
                        c360.Timestamp_Step_PreCheck_Completed__c = now;
                        c360.Timestamp_Step_Notes_Started__c = now;
                    } else if (data.previousWizardStep == 'Notes' && data.currentWizardStep == 'Review') {
                        c360.Timestamp_Step_Notes_Completed__c = now;
                        c360.Timestamp_Step_Review_Started__c = now;
                    }
                }
                
                if (c360NeedsUpdate) {
                    try {
                        update c360;
                    } catch (Exception e) {
                        Logger.error('HandoverService.saveHandoverData failed to update C360 for customer360Id: ' + customer360IdForLookup + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
                        Logger.saveLog();
                        throw e;
                    }
                }
            }
            
            result.success = true;
            result.message = 'Handover data saved successfully';
            result.recordId = customer360IdForLookup;
            
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.message = 'Error saving handover data: ' + e.getMessage();
            Logger.error('HandoverService.saveHandoverData failed. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            Logger.saveLog();
        }
        
        return result;
    }
    
    /**
     * @description Complete the handover - update C360 status and timestamp, mark AE task complete
     * Note: ACM Task is now created by the "Opportunity Closed Won" Flow, not here
     * @param data The handover completion data
     * @return SaveResult with success status
     */
    @AuraEnabled
    public static SaveResult completeHandover(Map<String, Object> dataMap) {
        SaveResult result = new SaveResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            // First save all the data using the same map
            result = saveHandoverData(dataMap);
            
            // Extract data we need for completion
            Id taskId = (Id)dataMap.get('taskId');
            Id customer360Id = (Id)dataMap.get('customer360Id');
            
            if (!result.success) {
                return result;
            }
            
            // Update Customer_360__c to Completed status with timestamp and ACM assignment date
            DateTime documentationCompletedTime = DateTime.now();
            Customer_360__c c360 = new Customer_360__c(Id = customer360Id);
            c360.Documentation_Status__c = 'Completed';
            c360.Timestamp_Documentation_Completed__c = documentationCompletedTime;
            c360.ACM_Assignment_Date__c = Date.today();
            
            // Calculate Time_To_Documentation_Completion__c if we have the Opportunity Contract Received timestamp
            if (taskId != null) {
                try {
                    Task taskRecord = [SELECT WhatId FROM Task WHERE Id = :taskId LIMIT 1];
                    if (taskRecord.WhatId != null && taskRecord.WhatId.getSObjectType() == Opportunity.SObjectType) {
                        Opportunity opp = [SELECT Timestamp_Contract_Recieved_Time_2__c FROM Opportunity WHERE Id = :taskRecord.WhatId LIMIT 1];
                        if (opp.Timestamp_Contract_Recieved_Time_2__c != null) {
                            Long businessMinutes = BusinessHoursUtility.calculateBusinessMinutes(opp.Timestamp_Contract_Recieved_Time_2__c, documentationCompletedTime);
                            c360.Time_To_Documentation_Completion__c = businessMinutes;
                        }
                    }
                } catch (Exception e) {
                    // Log but don't fail the handover for time calculation errors
                    Logger.error('HandoverService.completeHandover failed to calculate Time_To_Documentation_Completion__c for taskId: ' + taskId + '. Error: ' + e.getMessage());
                    Logger.saveLog();
                }
            }
            
            try {
                update c360;
            } catch (Exception e) {
                Logger.error('HandoverService.completeHandover failed to update C360 status for customer360Id: ' + customer360Id + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
                Logger.saveLog();
                throw e;
            }
            
            // Mark the AE Task as completed
            if (taskId != null) {
                Task t = new Task(Id = taskId);
                t.Status = 'Completed';
                try {
                    update t;
                } catch (Exception e) {
                    Logger.error('HandoverService.completeHandover failed to complete AE Task for taskId: ' + taskId + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
                    Logger.saveLog();
                    throw e;
                }
            }
            
            result.success = true;
            result.message = 'Handover completed successfully';
            result.recordId = customer360Id;
            
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.message = 'Error completing handover: ' + e.getMessage();
            Logger.error('HandoverService.completeHandover failed. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            Logger.saveLog();
        }
        
        return result;
    }
    
    /**
     * @description Calculate a date that is N working days from a start date (excludes weekends)
     * @param startDate The starting date
     * @param workingDays Number of working days to add
     * @return The calculated due date
     */
    @TestVisible
    private static Date calculateWorkingDays(Date startDate, Integer workingDays) {
        Date resultDate = startDate;
        Integer daysAdded = 0;
        
        while (daysAdded < workingDays) {
            resultDate = resultDate.addDays(1);
            // Get day of week (1 = Monday, 7 = Sunday in Salesforce)
            DateTime dt = DateTime.newInstance(resultDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = dt.format('u'); // 1-7 (Mon-Sun)
            
            // Skip weekends (Saturday = 6, Sunday = 7)
            if (dayOfWeek != '6' && dayOfWeek != '7') {
                daysAdded++;
            }
        }
        
        return resultDate;
    }
    
    /**
     * @description Invocable Action for Flows to calculate working days due date
     * Excludes weekends (Saturday and Sunday)
     * @param requests List of WorkingDaysRequest with startDate and workingDays
     * @return List of calculated due dates
     */
    @InvocableMethod(label='Calculate Working Days Due Date' 
                     description='Calculates due date by adding working days (excludes weekends). Use for SLA calculations.')
    public static List<Date> calculateWorkingDaysDueDate(List<WorkingDaysRequest> requests) {
        List<Date> results = new List<Date>();
        for (WorkingDaysRequest req : requests) {
            Date startDate = req.startDate != null ? req.startDate : Date.today();
            Integer days = req.workingDays != null ? req.workingDays : 1;
            results.add(calculateWorkingDays(startDate, days));
        }
        return results;
    }
    
    /**
     * @description Request wrapper for working days calculation (used by Flow Invocable Action)
     */
    public class WorkingDaysRequest {
        @InvocableVariable(required=true label='Start Date' description='The date to start counting from')
        public Date startDate;
        
        @InvocableVariable(required=true label='Number of Working Days' description='Number of working days to add (excludes weekends)')
        public Integer workingDays;
    }
    
    /**
     * @description Complete ACM Task with IHC feedback
     * Also updates the related Customer_360__c record with quality feedback
     * Note: Task custom fields (IHC_Scheduled_Timestamp__c, etc.) need to be created manually
     * in Setup > Object Manager > Task > Fields & Relationships
     * @param taskId The Task ID
     * @param ihcScheduledTimestamp When IHC was scheduled
     * @param ihcCompletedTimestamp When IHC was completed
     * @param documentationQuality Quality assessment
     * @param qualityComments Optional comments
     * @return SaveResult with success status
     */
    @AuraEnabled
    public static SaveResult completeACMTask(
        Id taskId,
        String ihcScheduledTimestamp,
        String ihcCompletedTimestamp,
        String documentationQuality,
        String qualityComments
    ) {
        SaveResult result = new SaveResult();
        
        try {
            // Query Task to get WhatId (Opportunity)
            Task taskRecord = [SELECT Id, WhatId FROM Task WHERE Id = :taskId LIMIT 1];
            
            // Build dynamic update to handle missing custom fields
            Task t = new Task(Id = taskId);
            t.Status = 'Completed';
            
            // Parse and set scheduled timestamp only if provided
            if (String.isNotBlank(ihcScheduledTimestamp)) {
                DateTime scheduledDT = DateTime.valueOf(ihcScheduledTimestamp.replace('T', ' ').replace('Z', ''));
                t.put('Timestamp_Internal_HO_Call_Scheduled__c', scheduledDT);
            }
            
            // Parse and set completed timestamp
            if (String.isNotBlank(ihcCompletedTimestamp)) {
                DateTime completedDT = DateTime.valueOf(ihcCompletedTimestamp.replace('T', ' ').replace('Z', ''));
                t.put('Timestamp_Internal_HO_Call_Completed__c', completedDT);
            }
            
            // Set other custom fields for IHC feedback
            t.put('Handover_Documentation_Quality__c', documentationQuality);
            t.put('Handover_Quality_Comments__c', qualityComments);
            
            update t;
            
            // Also update the Customer_360__c record with quality feedback
            if (taskRecord.WhatId != null) {
                Id accountId = null;
                DateTime contractReceivedDT = null;
                Schema.SObjectType whatType = taskRecord.WhatId.getSObjectType();
                
                if (whatType == Opportunity.SObjectType) {
                    Opportunity opp = [SELECT AccountId, Timestamp_Contract_Recieved_Time_2__c FROM Opportunity WHERE Id = :taskRecord.WhatId LIMIT 1];
                    accountId = opp.AccountId;
                    contractReceivedDT = opp.Timestamp_Contract_Recieved_Time_2__c;
                } else if (whatType == Account.SObjectType) {
                    accountId = taskRecord.WhatId;
                }
                
                if (accountId != null) {
                    List<Customer_360__c> c360List = [
                        SELECT Id, Account__r.Timestamp_ACM_Assignment__c
                        FROM Customer_360__c 
                        WHERE Account__c = :accountId 
                        AND Type__c = 'Pilot Handover'
                        AND Documentation_Status__c = 'Completed'
                        ORDER BY Timestamp_Documentation_Completed__c DESC
                        LIMIT 1
                    ];
                    
                    if (!c360List.isEmpty()) {
                        Customer_360__c c360 = c360List[0];
                        c360.Handover_Documentation_Quality__c = documentationQuality;
                        c360.Handover_Quality_Comments__c = qualityComments;
                        
                        DateTime scheduledDT = null;
                        DateTime completedDT = null;
                        
                        if (String.isNotBlank(ihcScheduledTimestamp)) {
                            scheduledDT = DateTime.valueOf(ihcScheduledTimestamp.replace('T', ' ').replace('Z', ''));
                            c360.IHC_Scheduled_Date__c = scheduledDT;
                        }
                        
                        if (String.isNotBlank(ihcCompletedTimestamp)) {
                            completedDT = DateTime.valueOf(ihcCompletedTimestamp.replace('T', ' ').replace('Z', ''));
                            c360.IHC_Meeting_Date__c = completedDT;
                        }
                        
                        DateTime acmAssignmentDT = c360.Account__r.Timestamp_ACM_Assignment__c;
                        
                        if (acmAssignmentDT != null && completedDT != null) {
                            c360.Time_ACM_To_IHC_Completed__c = BusinessHoursUtility.calculateBusinessMinutes(acmAssignmentDT, completedDT);
                        }
                        
                        if (acmAssignmentDT != null && contractReceivedDT != null) {
                            c360.Time_To_ACM_Assignment__c = BusinessHoursUtility.calculateBusinessMinutes(contractReceivedDT, acmAssignmentDT);
                        }
                        
                        try {
                            update c360;
                        } catch (Exception e) {
                            Logger.error('HandoverService.completeACMTask failed to update C360 for accountId: ' + accountId + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
                            Logger.saveLog();
                        }
                    }
                }
            }
            
            result.success = true;
            result.message = 'Internal Handover Call successfully completed';
            result.recordId = taskId;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error completing ACM task: ' + e.getMessage();
            Logger.error('HandoverService.completeACMTask failed for taskId: ' + taskId + '. Error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            Logger.saveLog();
        }
        
        return result;
    }
    
    /**
     * @description Update time spent on a wizard section (accumulative)
     * @param customer360Id The Customer_360__c record ID
     * @param sectionName The section name (PreCheck or Notes)
     * @param minutesSpent Minutes spent on the section
     * @return SaveResult with success status
     */
    @AuraEnabled
    public static SaveResult updateTimeSpent(Id customer360Id, String sectionName, Integer minutesSpent) {
        SaveResult result = new SaveResult();
        
        try {
            // Query current time spent
            Customer_360__c c360 = [
                SELECT Id, Time_Spent_PreCheck_Minutes__c, Time_Spent_Notes_Minutes__c
                FROM Customer_360__c
                WHERE Id = :customer360Id
                LIMIT 1
            ];
            
            // Accumulate time based on section
            if (sectionName == 'PreCheck') {
                Decimal currentTime = c360.Time_Spent_PreCheck_Minutes__c != null ? c360.Time_Spent_PreCheck_Minutes__c : 0;
                c360.Time_Spent_PreCheck_Minutes__c = currentTime + minutesSpent;
            } else if (sectionName == 'Notes') {
                Decimal currentTime = c360.Time_Spent_Notes_Minutes__c != null ? c360.Time_Spent_Notes_Minutes__c : 0;
                c360.Time_Spent_Notes_Minutes__c = currentTime + minutesSpent;
            }
            
            update c360;
            
            result.success = true;
            result.message = 'Time spent updated successfully';
            result.recordId = customer360Id;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error updating time spent: ' + e.getMessage();
            Logger.error('HandoverService.updateTimeSpent failed for customer360Id: ' + customer360Id + ', section: ' + sectionName + '. Error: ' + e.getMessage());
            Logger.saveLog();
        }
        
        return result;
    }
    
    /**
     * @description Check if handover is already completed for this Task
     * @param taskId The Task ID
     * @return HandoverStatus with completion info and Customer_360 record link
     */
    @AuraEnabled
    public static HandoverStatus checkHandoverStatus(Id taskId) {
        HandoverStatus status = new HandoverStatus();
        status.isCompleted = false;
        
        try {
            Task taskRecord = [
                SELECT Id, Status, WhatId
                FROM Task
                WHERE Id = :taskId
                LIMIT 1
            ];
            
            // Check if task is completed
            if (taskRecord.Status == 'Completed') {
                status.isCompleted = true;
                
                Id accountId = null;
                Schema.SObjectType whatType = taskRecord.WhatId != null ? taskRecord.WhatId.getSObjectType() : null;
                
                if (whatType == Opportunity.SObjectType) {
                    Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :taskRecord.WhatId LIMIT 1];
                    accountId = opp.AccountId;
                } else if (whatType == Account.SObjectType) {
                    accountId = taskRecord.WhatId;
                }
                
                if (accountId != null) {
                    List<Customer_360__c> c360List = [
                        SELECT Id, Account__c, Account__r.Name
                        FROM Customer_360__c
                        WHERE Account__c = :accountId
                        AND Type__c = 'Pilot Handover'
                        AND Documentation_Status__c = 'Completed'
                        ORDER BY Timestamp_Documentation_Completed__c DESC
                        LIMIT 1
                    ];
                    
                    if (!c360List.isEmpty()) {
                        status.customer360Id = c360List[0].Id;
                        status.accountId = c360List[0].Account__c;
                        status.accountName = c360List[0].Account__r.Name;
                        status.customer360Url = '/lightning/r/Customer_360__c/' + c360List[0].Id + '/view';
                    }
                }
            }
        } catch (Exception e) {
            Logger.error('HandoverService.checkHandoverStatus failed for taskId: ' + taskId + '. Error: ' + e.getMessage());
            Logger.saveLog();
        }
        
        return status;
    }
    
    /**
     * @description Resolve the AE handover Task for a given Opportunity.
     * Used when the "Prepare Handover" button is clicked from an Opportunity.
     * Finds the Task by WhatId + Type, then delegates to checkHandoverStatus.
     * @param opportunityId The Opportunity ID
     * @return HandoverStatus with taskId populated so the UI can open the wizard
     */
    @AuraEnabled
    public static HandoverStatus resolveHandoverTask(Id opportunityId) {
        HandoverStatus status = new HandoverStatus();
        status.isCompleted = false;
        
        try {
            List<Task> tasks = [
                SELECT Id, Status
                FROM Task
                WHERE WhatId = :opportunityId
                AND Type = 'Pilot Handover AE'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (tasks.isEmpty()) {
                throw new AuraHandledException(
                    'Kein Handover-Task gefunden. Bitte stellen Sie sicher, dass die Opportunity den Status "Contract received" erreicht hat.'
                );
            }
            
            status = checkHandoverStatus(tasks[0].Id);
            status.taskId = tasks[0].Id;
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            Logger.error('HandoverService.resolveHandoverTask failed for opportunityId: ' + opportunityId + '. Error: ' + e.getMessage());
            Logger.saveLog();
            throw new AuraHandledException('Error resolving handover task: ' + e.getMessage());
        }
        
        return status;
    }
    
    /**
     * @description Get contact details by ID for refreshing UI
     * @param contactId The Contact ID
     * @return ContactInfo with contact details
     */
    @AuraEnabled
    public static ContactInfo getContactDetails(Id contactId) {
        try {
            Contact c = [
                SELECT Id, FirstName, LastName, Email, Phone, Title
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];
            
            ContactInfo info = new ContactInfo();
            info.id = c.Id;
            info.firstName = c.FirstName;
            info.lastName = c.LastName;
            info.email = c.Email;
            info.phone = c.Phone;
            info.title = c.Title;
            
            return info;
        } catch (Exception e) {
            Logger.error('HandoverService.getContactDetails failed for contactId: ' + contactId + '. Error: ' + e.getMessage());
            Logger.saveLog();
            throw new AuraHandledException('Error loading contact: ' + e.getMessage());
        }
    }
    
    /**
     * @description Helper method to populate contact info in the context
     */
    private static void populateContactInfo(HandoverContext context, Id strategicId, 
            Contact strategicContact, Id operationalId, Contact operationalContact) {
        // Strategic Contact
        if (strategicId != null && strategicContact != null) {
            context.strategicContact = new ContactInfo();
            context.strategicContact.id = strategicId;
            context.strategicContact.firstName = strategicContact.FirstName;
            context.strategicContact.lastName = strategicContact.LastName;
            context.strategicContact.email = strategicContact.Email;
            context.strategicContact.phone = strategicContact.Phone;
            context.strategicContact.title = strategicContact.Title;
        }
        
        // Operational Contact
        if (operationalId != null && operationalContact != null) {
            context.operationalContact = new ContactInfo();
            context.operationalContact.id = operationalId;
            context.operationalContact.firstName = operationalContact.FirstName;
            context.operationalContact.lastName = operationalContact.LastName;
            context.operationalContact.email = operationalContact.Email;
            context.operationalContact.phone = operationalContact.Phone;
            context.operationalContact.title = operationalContact.Title;
        }
    }
    
    // ============ WRAPPER CLASSES ============
    
    /**
     * @description Wrapper for handover context data
     */
    public class HandoverContext {
        @AuraEnabled public Id taskId;
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public Integer employees;
        @AuraEnabled public String openJobs;
        @AuraEnabled public Decimal estimatedWalletSize;
        @AuraEnabled public String gtmMotion;
        @AuraEnabled public Id parentAccountId;
        @AuraEnabled public String parentAccountName;
        @AuraEnabled public String ultimateParentAccount; // Formula field value (text)
        @AuraEnabled public Id customer360Id;
        @AuraEnabled public ContactInfo strategicContact;
        @AuraEnabled public ContactInfo operationalContact;
        // Opportunity banner fields
        @AuraEnabled public Date opportunityCloseDate;
        @AuraEnabled public Decimal opportunityAmount;
        @AuraEnabled public String productSold;
        // Resume-related fields from Customer_360__c
        @AuraEnabled public String documentationStatus;
        @AuraEnabled public String currentWizardStep;
        @AuraEnabled public String customerGoals;
        @AuraEnabled public String risks;
        @AuraEnabled public Decimal relationshipRating;
        @AuraEnabled public String relationshipReason;
        @AuraEnabled public String keyLogistics;
        @AuraEnabled public String dos;
        @AuraEnabled public String donts;
        @AuraEnabled public String other;
        @AuraEnabled public String handoverUrgency;
    }
    
    /**
     * @description Wrapper for contact information
     */
    public class ContactInfo {
        @AuraEnabled public Id id;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String title; // Changed from 'role' to 'title'
    }
    
    /**
     * @description Parse Map<String, Object> into HandoverSaveRequest wrapper
     * @param dataMap The map from LWC
     * @return HandoverSaveRequest populated wrapper
     */
    private static HandoverSaveRequest parseDataMap(Map<String, Object> dataMap) {
        HandoverSaveRequest data = new HandoverSaveRequest();
        data.taskId = (Id)dataMap.get('taskId');
        data.accountId = (Id)dataMap.get('accountId');
        data.customer360Id = (Id)dataMap.get('customer360Id');
        data.employees = dataMap.get('employees') != null ? Integer.valueOf(dataMap.get('employees')) : null;
        data.openJobs = (String)dataMap.get('openJobs');
        data.estimatedWalletSize = dataMap.get('estimatedWalletSize') != null ? Decimal.valueOf(String.valueOf(dataMap.get('estimatedWalletSize'))) : null;
        data.parentAccountId = dataMap.get('parentAccountId') != null ? (Id)dataMap.get('parentAccountId') : null;
        data.strategicContactId = dataMap.get('strategicContactId') != null ? (Id)dataMap.get('strategicContactId') : null;
        data.operationalContactId = dataMap.get('operationalContactId') != null ? (Id)dataMap.get('operationalContactId') : null;
        data.customerGoals = (String)dataMap.get('customerGoals');
        data.risks = (String)dataMap.get('risks');
        data.relationshipRating = dataMap.get('relationshipRating') != null ? Decimal.valueOf(String.valueOf(dataMap.get('relationshipRating'))) : null;
        data.relationshipReason = (String)dataMap.get('relationshipReason');
        data.keyLogistics = (String)dataMap.get('keyLogistics');
        data.dos = (String)dataMap.get('dos');
        data.donts = (String)dataMap.get('donts');
        data.other = (String)dataMap.get('other');
        data.handoverUrgency = (String)dataMap.get('handoverUrgency');
        data.documentationStatus = (String)dataMap.get('documentationStatus');
        data.currentWizardStep = (String)dataMap.get('currentWizardStep');
        data.previousWizardStep = (String)dataMap.get('previousWizardStep');
        return data;
    }
    
    /**
     * @description Request wrapper for saving handover data
     */
    public class HandoverSaveRequest {
        public Id taskId;
        public Id accountId;
        public Id customer360Id;
        public Integer employees;
        public String openJobs;
        public Decimal estimatedWalletSize;
        public Id parentAccountId;
        public Id strategicContactId;
        public Id operationalContactId;
        public String customerGoals;
        public String risks;
        public Decimal relationshipRating;
        public String relationshipReason;
        public String keyLogistics;
        public String dos;
        public String donts;
        public String other;
        public String handoverUrgency;
        public String documentationStatus;
        public String currentWizardStep;
        public String previousWizardStep;
    }
    
    /**
     * @description Result wrapper for save operations
     */
    public class SaveResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id recordId;
    }
    
    /**
     * @description Wrapper for handover completion status check
     */
    public class HandoverStatus {
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public Id taskId;
        @AuraEnabled public Id customer360Id;
        @AuraEnabled public String customer360Url;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
    }
}