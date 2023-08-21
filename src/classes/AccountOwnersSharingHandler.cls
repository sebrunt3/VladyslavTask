public with sharing class AccountOwnersSharingHandler {
    public static void afterInsertSharingOwners(Map<Id, Account> accountMap) {
        Map<Id, List<Account>> relatedContactToAccount = getMapRelatedContactToAccount(accountMap);

        if (relatedContactToAccount.isEmpty()) {
            return;
        }

        try {
            List<Contact> contactsToUpdate = queryContactRelatedOwners(relatedContactToAccount.keySet());
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
            List<Contact> contactsToUpdate = queryContactRelatedOwners(relatedContactToAccount.keySet());
            Map<Id, Map<Id, List<Account>>> relatedContactToOwnersAmount = getMapRelatedContactToOwnersAmountDuplicate(relatedContactToAccount.keySet());
            updateContactRelatedOwners(relatedContactToAccount, accountOldMap, contactsToUpdate, relatedContactToOwnersAmount);
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
            List<Contact> contactsToUpdate = queryContactRelatedOwners(relatedContactToAccount.keySet());
            Map<Id, Map<Id, List<Account>>> relatedContactToOwnersAmount = getMapRelatedContactToOwnersAmountDuplicate(relatedContactToAccount.keySet());
            removeContactRelatedOwners(relatedContactToAccount, contactsToUpdate, relatedContactToOwnersAmount);
        } catch (Exception e) {
            //LogService.getLogger().logException(e, 'AccountOwnersSharingHandler.beforeDeleteSharingOwners');
            throw e;
        }
    }

    // Method to get a map of Contact IDs to related Account records
    private static Map<Id, List<Account>> getMapRelatedContactToAccount(Map<Id, Account> accountMap) {
        Map<Id, List<Account>> relatedContactToAccount = new Map<Id, List<Account>>();

        List<AccountContactRelationship__c> accountContactRelationships = [
                SELECT ContactId__c, AccountId__c
                FROM AccountContactRelationship__c
                WHERE AccountId__c IN :accountMap.keySet()
        ];

        for (AccountContactRelationship__c accContRelationship : accountContactRelationships) {
            if (!relatedContactToAccount.containsKey(accContRelationship.ContactId__c)) {
                relatedContactToAccount.put(accContRelationship.ContactId__c, new List<Account>());
            }
            relatedContactToAccount.get(accContRelationship.ContactId__c).add(accountMap.get(accContRelationship.AccountId__c));
        }

        return relatedContactToAccount;
    }

    private static Map<Id, Map<Id, List<Account>>> getMapRelatedContactToOwnersAmountDuplicate(Set<Id> contactIdsSet) {
        Map<Id, Map<Id, List<Account>>> relatedContactToOwnersAmountDuplicate = new Map<Id, Map<Id, List<Account>>>();
        Map<Id, Id> accountIdsToContactIdsMap = new Map<Id, Id>();

        List<AccountContactRelationship__c> accountContactRelationships = [
                SELECT ContactId__c, AccountId__c
                FROM AccountContactRelationship__c
                WHERE ContactId__c IN :contactIdsSet
        ];

        for (AccountContactRelationship__c relationship : accountContactRelationships) {
            accountIdsToContactIdsMap.put(relationship.AccountId__c, relationship.ContactId__c);
        }

        List<Account> accountList = [
                SELECT Id, OwnerId
                FROM Account
                WHERE Id IN :accountIdsToContactIdsMap.keySet()
        ];

        for (Account acc : accountList) {
            Id contactId = accountIdsToContactIdsMap.get(acc.Id);

            if (!relatedContactToOwnersAmountDuplicate.containsKey(contactId)) {
                relatedContactToOwnersAmountDuplicate.put(contactId, new Map<Id, List<Account>>());
            }

            if (!relatedContactToOwnersAmountDuplicate.get(contactId).containsKey(acc.OwnerId)) {
                relatedContactToOwnersAmountDuplicate.get(contactId).put(acc.OwnerId, new List<Account>());
            }

            relatedContactToOwnersAmountDuplicate.get(contactId).get(acc.OwnerId).add(acc);
        }

        return relatedContactToOwnersAmountDuplicate;
    }

    // Method to query all Contact records related to Owners
    private static List<Contact> queryContactRelatedOwners(Set<Id> contactIdsSet) {
        return [
                SELECT Id, RelatedAccountOwner__c
                FROM Contact
                WHERE Id IN :contactIdsSet
        ];
    }

    // Method to invoke in Insert context and add new Owners records in RelatedAccountOwner__c field
    private static void addContactRelatedOwners(Map<Id, List<Account>> relatedContactToAccount, List<Contact> contactsToUpdate) {
        for (Contact contact : contactsToUpdate) {
            Set<String> relatedAccountOwnersSet = String.isBlank(contact.RelatedAccountOwner__c) ?
                    new Set<String>() : new Set<String>(contact.RelatedAccountOwner__c.split(','));

            for (Account account : relatedContactToAccount.get(contact.Id)) {
                relatedAccountOwnersSet.add(account.OwnerId);
            }

            contact.RelatedAccountOwner__c = String.join(new List<String>(relatedAccountOwnersSet), ',');
        }

        update contactsToUpdate;
    }

    // Method to invoke in Delete context and remove Owners records in RelatedAccountOwner__c field
    private static void removeContactRelatedOwners(Map<Id, List<Account>> relatedContactToAccount, List<Contact> contactsToUpdate, Map<Id, Map<Id, List<Account>>> relatedContactToOwnersAmount) {
        for (Contact contact : contactsToUpdate) {
            Set<String> relatedAccountOwnersSet = String.isBlank(contact.RelatedAccountOwner__c) ?
                    new Set<String>() : new Set<String>(contact.RelatedAccountOwner__c.split(','));

            for (Account account : relatedContactToAccount.get(contact.Id)) {
                if (relatedContactToOwnersAmount.get(contact.Id).get(account.OwnerId).size() == 1) {
                    relatedAccountOwnersSet.remove(account.OwnerId);
                }
            }

            contact.RelatedAccountOwner__c = String.join(new List<String>(relatedAccountOwnersSet), ',');
        }

        update contactsToUpdate;
    }

    // Method to invoke in Update context and update Owners records in RelatedAccountOwner__c field
    private static void updateContactRelatedOwners(Map<Id, List<Account>> relatedContactToAccount, Map<Id, Account> accountOldMap, List<Contact> contactsToUpdate, Map<Id, Map<Id, List<Account>>> relatedContactToOwnersAmount) {
        for (Contact contact : contactsToUpdate) {
            Set<String> relatedAccountOwnersSet = String.isBlank(contact.RelatedAccountOwner__c) ?
                    new Set<String>() : new Set<String>(contact.RelatedAccountOwner__c.split(','));

            for (Account account : relatedContactToAccount.get(contact.Id)) {
                if (account.OwnerId != accountOldMap.get(account.Id).OwnerId) {
                    relatedAccountOwnersSet.add(account.OwnerId);

                    if (relatedContactToOwnersAmount.get(contact.Id).get(account.OwnerId).size() == 1) {
                        relatedAccountOwnersSet.remove(accountOldMap.get(account.Id).OwnerId);
                    }
                }
            }

            contact.RelatedAccountOwner__c = String.join(new List<String>(relatedAccountOwnersSet), ',');
        }

        update contactsToUpdate;
    }
}