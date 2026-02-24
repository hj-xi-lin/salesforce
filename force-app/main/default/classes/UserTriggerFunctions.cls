/*
 *      @author Arun Kumar
 *      @date   02-May-2022
 *      @description Apex class to handle all the business logic related to user updates
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      Arun Kumar                  02-May-2022             Created for RO-879
 * 
 */

public without sharing class UserTriggerFunctions {
    
    public static void checkServiceCountry(List<User> newUserList, Map<Id, User> oldUserMap, Boolean isUpdate, Boolean isInsert){
        
        Map<User, Id> userVsRoleMap = new Map<User, Id>();
        
        for(User u : newUserList){
            if(isInsert && u.UserRoleId != null){
                userVsRoleMap.put(u, u.UserRoleId);
            }
        }
        
        if(isUpdate){
            for(User u: oldUserMap.values()){
                if(oldUserMap.get(u.Id).UserRoleId != u.UserRoleId){
                    userVsRoleMap.put(u, u.UserRoleId);
                }
            }
        }

        if(!userVsRoleMap.isEmpty()){
            updateServiceCountry(userVsRoleMap);
        }
    }

    public static void updateServiceCountry(Map<User, Id> userVsRoleMap){

        Map<String, Record_Access_Rule__mdt> roleVsCountrymdt = Record_Access_Rule__mdt.getall();
        Map<Id, UserRole> roleMap = new Map<Id, UserRole>([SELECT DeveloperName FROM UserRole WHERE Id IN :userVsRoleMap.values()]);
        
        for(String roleAccess : roleVsCountrymdt.keySet()){
            for(User u : userVsRoleMap.keySet()){
                if(!roleMap.isEmpty() && userVsRoleMap.containsKey(u) && roleMap.containsKey(userVsRoleMap.get(u))){
                    u.Service_Country__c = roleVsCountrymdt.get(String.valueOf(roleMap.get(userVsRoleMap.get(u)).DeveloperName)).Service_Country__c;
                }
            }
        }
    }
}