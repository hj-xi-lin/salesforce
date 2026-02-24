/*
 *      @author Arun Kumar
 *      @date   10-Feb-2023
 *      @description   Class to handle the business logic on Quote Process 2.0
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      
 * 
 */

public with sharing class quoteProcess {
    
    /**
    @Methodname     : createQuoteLineItems
    @Param          : List<InputVariables> defined inside the class
    @Return         : Null
    @Description    : To create quoteLineItems for the quote created through flow
    **/
    @InvocableMethod(Label = 'Create Quote Line Item')
    public static void createQuoteLineItems(List<InputVariables> inputList){
        //Get input value from flow
        List<String> productList = new List<String>();
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        List<PricebookEntry> priceBookEntryList = new List<PricebookEntry>();
        List<String> productDetailsList = String.valueOf(System.Label.QUOTE_PRODUCTS).split(',');
        Map<String, Integer> productNamevsQuantityMap = new Map<String, Integer>();
        Map<String, Integer> productNamevsUnitPriceMap = new Map<String, Integer>();
            
        if(!productDetailsList.isEmpty()){
            for(String str :productDetailsList){
                productList.add(str.substringBefore(':'));
                productNamevsQuantityMap.put(str.substringBefore(':'), Integer.valueOf(str.substringAfter(':').substringBefore('-')));
                productNamevsUnitPriceMap.put(str.substringBefore(':'), Integer.valueOf(str.substringAfter(':').substringAfter('-')));
            }
        }
        
        if(!productList.isEmpty()){
            priceBookEntryList = [SELECT Id, Name FROM PricebookEntry WHERE Name IN :productList];
        }
        
        if(!priceBookEntryList.isEmpty()){
           for(Integer i=0; i<priceBookEntryList.size(); i++){
                QuoteLineItem qli = new QuoteLineItem();
                qli.QuoteId = inputList.get(0).quoteId;
                qli.Quantity = productNamevsQuantityMap.get(priceBookEntryList[i].Name);
                qli.UnitPrice = productNamevsUnitPriceMap.get(priceBookEntryList[i].Name);
                qli.pricebookentryId = priceBookEntryList[i].Id;
                qliList.add(qli);
            } 
        }
        
        try{
            insert qliList;
        }catch(Exception e){
            System.debug('Error while creating quote line item -'+e.getMessage());
        }
    }
    
    public class InputVariables{
        @InvocableVariable
        public Id quoteId;
    }
}