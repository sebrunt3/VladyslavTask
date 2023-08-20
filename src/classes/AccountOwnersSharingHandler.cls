public with sharing class AccountOwnersSharingHandler {
    public static void afterInsertSharingOwners(Map<Id, Account> accountMap) {
        Map<Id, List<Account>> relatedContactToAccount = getMapRelatedContactToAccount(accountMap);

        if (relatedContactToAccount.isEmpty()) {
            return;
        }

        try {
            List<Contact> contactsToUpdate = queryContactRelatedOwners(relatedContactToAccount);
            addContactRelatedOwners(relatedContactToAccount, contactsToUpdate);
        } catch (Exception e) {
            //LogService.getLogger().logException(e, 'AccountOwnersSharingHandler.afterInsertSharingOwners');
            throw e;
        }
    }

    public static void afterUpdateSharingOwners(Map<Id, Account> accountNewMap, Map<Id, Account> accountOldMap) {
        Map<Id, List<Account>> relatedContactToAccount = getMapRelatedContactToAccount(accountNewMap);

        if (relatedContactToAccount.isEmpty()) {
            return;
        }

        try {
            List<Contact> contactsToUpdate = queryContactRelatedOwners(relatedContactToAccount);
            updateContactRelatedOwners(relatedContactToAccount, accountOldMap, contactsToUpdate);
        } catch (Exception e) {
            //LogService.getLogger().logException(e, 'AccountOwnersSharingHandler.afterUpdateSharingOwners');
            throw e;
        }
    }

    public static void beforeDeleteSharingOwners(Map<Id, Account> accountMap) {
        Map<Id, List<Account>> relatedContactToAccount = getMapRelatedContactToAccount(accountMap);

        if (relatedContactToAccount.isEmpty()) {
            return;
        }

        try {
            List<Contact> contactsToUpdate = queryContactRelatedOwners(relatedContactToAccount);
            removeContactRelatedOwners(relatedContactToAccount, contactsToUpdate);
        } catch (Exception e) {
            //LogService.getLogger().logException(e, 'AccountOwnersSharingHandler.beforeDeleteSharingOwners');
            throw e;
        }
    }

    // Method to get a map of Contact IDs to related Account records
    private static Map<Id, List<Account>> getMapRelatedContactToAccount(Map<Id, Account> accountMap) {
        Map<Id, List<Account>> relatedContactToAccount = new Map<Id, List<Account>>();

        Set<Id> accountIds = new Set<Id>(accountMap.keySet());
        List<AccountContactRelationship__c> accountContactRelationships = [
                SELECT ContactId__c, AccountId__c
                FROM AccountContactRelationship__c
                WHERE AccountId__c IN :accountIds
        ];

        for (AccountContactRelationship__c accContRelationship : accountContactRelationships) {
            if (!relatedContactToAccount.containsKey(accContRelationship.ContactId__c)) {
                relatedContactToAccount.put(accContRelationship.ContactId__c, new List<Account>());
            }
            relatedContactToAccount.get(accContRelationship.ContactId__c).add(accountMap.get(accContRelationship.AccountId__c));
        }

        return relatedContactToAccount;
    }

    // Method to update the RelatedAccountOwner__c field on Contact records
    private static List<Contact> queryContactRelatedOwners(Map<Id, List<Account>> relatedContactToAccount) {
        return [
                SELECT Id, RelatedAccountOwner__c
                FROM Contact
                WHERE Id IN :relatedContactToAccount.keySet()
        ];
    }

    private static void addContactRelatedOwners(Map<Id, List<Account>> relatedContactToAccount, List<Contact> contactsToUpdate) {
        for (Contact contact : contactsToUpdate) {
            Set<String> relatedAccountOwnersSet = new Set<String>(contact.RelatedAccountOwner__c.split(','));

            for (Account account : relatedContactToAccount.get(contact.Id)) {
                relatedAccountOwnersSet.add(account.OwnerId);
            }

            contact.RelatedAccountOwner__c = String.join(new List<String>(relatedAccountOwnersSet), ',');
        }

        update contactsToUpdate;
    }

    private static void removeContactRelatedOwners(Map<Id, List<Account>> relatedContactToAccount, List<Contact> contactsToUpdate) {
        for (Contact contact : contactsToUpdate) {
            Set<String> relatedAccountOwnersSet = new Set<String>(contact.RelatedAccountOwner__c.split(','));

            for (Account account : relatedContactToAccount.get(contact.Id)) {
                relatedAccountOwnersSet.remove(account.OwnerId);
            }

            contact.RelatedAccountOwner__c = String.join(new List<String>(relatedAccountOwnersSet), ',');
        }

        update contactsToUpdate;
    }

    private static void updateContactRelatedOwners(Map<Id, List<Account>> relatedContactToAccount, Map<Id, Account> accountOldMap, List<Contact> contactsToUpdate) {
        for (Contact contact : contactsToUpdate) {
            Set<String> relatedAccountOwnersSet = new Set<String>(contact.RelatedAccountOwner__c.split(','));

            for (Account account : relatedContactToAccount.get(contact.Id)) { 
                if (account.OwnerId != accountOldMap.get(account.Id).OwnerId) {
                    relatedAccountOwnersSet.add(account.OwnerId);
                    relatedAccountOwnersSet.remove(accountOldMap.get(account.Id).OwnerId);
                }
            }

            contact.RelatedAccountOwner__c = String.join(new List<String>(relatedAccountOwnersSet), ',');
        }

        update contactsToUpdate;
    }
}