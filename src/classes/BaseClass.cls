/**
 * @description BaseClass to extend that helps handling with Database Commits and relationships
 *
 * @author P. Victoriano
 * @date 18/11/2017
 **/
public virtual class BaseClass implements IBaseClass {
    @TestVisible
    private List<Schema.sObjectType> lCommitOrder {get; set;}
    //
    @TestVisible
    private List<String> commitOrderList {get; set;}
    private Map<String, List<SObject>> mapRecordsInsert {get; set;}
    private Map<String, List<SObject>> mapRecordsUpdate {get; set;}
    private Map<String, List<SObject>> mapRemove {get; set;}
    private Map<String, Records> mapRelationship {get; set;}
    /**
     * Constructor Overloaded class is virtual and can be extended or initialized
     *
     * @usage
     * BaseClass bc1 = new BaseClass();
     * bc1.initialize(new List<Schema.sObjectType>{...});
     *         //constructor called
     * BaseClass bc2 = new BaseClass(new List<Schema.sObjectType>{...});
     *         //extended
     * public ControllerClass extends BaseClass{
     *     public ControllerClass(){
     *         super(new List<Schema.sObjectType>{...});
     *     }
     */
    public BaseClass() {}
    /**
     * Virtual Class implements database management
     *
     * @param lOrder
     */
    public BaseClass(List<Schema.sObjectType> lOrder) {
        initialize(lOrder);
    }
    /**
     * @description Initializes Order Commit Handler
     * @param       listCommitOrder Schema.sObjectType[]
     * @example
     *              List<Schema.sObjectType> {
     *                  Account.sObjectType,
     *                  Contact.sObjectType
     *               }
     */
    public void initialize(List<Schema.sObjectType> listCommitOrder) {
        lCommitOrder = listCommitOrder;
        instantiate();
        //Todo
    }
    /**
     * @description Adds a single record
     * @param       sobj
     * @return
     */
    public void push(SObject sobj) {
        push(sobj, null, null);
        RestContext
    }
    /**
     * @description Adds a Record to be Related with Parent
     * @param       sobj
     * @param       relatedField
     * @param       relatedRecord
     * @return
     */
    public void push(SObject sobj, Schema.sObjectField relatedField, SObject relatedRecord) {
        String stype;

        try {
            if (sobj != null && validate(sobj)) {
                stype = sobj.getSObjectType().getDescribe().getName();
                relate(sobj, relatedField, relatedRecord);

                if (sobj.Id != null) {
                    mapRecordsUpdate.get(stype).add(sobj);
                } else {
                    mapRecordsInsert.get(stype).add(sobj);
                }
            }
        } catch (Exception e) {
            System.debug('!!@@##: Exception Push: ' + e.getMessage());
            throw new BaseClassException(e.getMessage());
        }
    }
    /**
     * @description Removes a Record
     * @param       sobj
     * @return
     */
    public void pop(SObject sobj) {
        String stype;

        if (sobj != null && validate(sobj)) {
            stype = sobj.getSObjectType().getDescribe().getName();
            mapRemove.get(stype).add(sobj);
        }
    }
    public void pop(List<SObject> sobjlist) {
        if (sobjList != null) {
            for (SObject sobj : sobjList) {
                pop(sobj);
            }
        }
    }
    public void noempt(){

    }
    /**
     * @description creates a relationship between source and target
     * @param       sobj            source
     * @param       relatedField    sObjectField
     * @param       relatedRecord   target
     */
    public void relate(SObject sobj, Schema.sObjectField relatedField, SObject relatedRecord) {
        if (sobj != null && relatedField != null && relatedRecord != null) {
            String stype = sobj.getSObjectType().getDescribe().getName();
            mapRelationship.get(stype).add(sobj, relatedField, relatedRecord);
        }
    }
    /**
     * @description retrieves non-commited records for insert / update
     * @param       sotType         Schema.sObjectType
     * @return                      List
     */
    public List<SObject> getRecordsByType(Schema.sObjectType sotType) {
        List<SObject> lRecordsbyType = new List<SObject>();
        String stype = sotType.getDescribe().getName();

        if (mapRecordsInsert.containsKey(stype)) {
            lRecordsbyType.addAll(mapRecordsInsert.get(stype));
        }

        if (mapRecordsUpdate.containsKey(stype)) {
            lRecordsbyType.addAll(mapRecordsUpdate.get(stype));
        }

        return lRecordsbyType;
    }
    /**
     * @description Performs Save and Commit to Database
     *              clears last saved records
     * @return
     */
    public Boolean commitRecords() {
        Savepoint sp = Database.setSavepoint();
        Boolean issuccess = false;
        List<SObject> lRecInsert = new List<SObject>();
        List<SObject> lRecUpdate = new List<SObject>();
        List<SObject> lRecDelete = new List<SObject>();

        try {
            for (String stype : commitOrderList) {
                //Insert
                mapRelationship.get(stype).createRelationship();
                //
                lRecInsert = mapRecordsInsert.get(stype);

                if (!lRecInsert.isEmpty()) {
                    insert lRecInsert;
                }

                //Update
                lRecUpdate = mapRecordsUpdate.get(stype);

                if (!lRecUpdate.isEmpty()) {
                    update lRecUpdate;
                }

                //Delete
                lRecDelete = mapRemove.get(stype);

                if (!lRecDelete.isEmpty()) {
                    delete lRecDelete;
                }
            }

            issuccess = true;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new BaseClassException(e.getMessage());
        } finally {
            //Clears map and recreates a new set
            instantiate();
        }

        return issuccess;
    }
    /**
     * @description Performs Partial Save and Commit to Database
     *              On Error it Returns a list of Records that failed
     *              clears last saved records
     * @return BaseClass.CommitRecord
     */
    public List<CommitRecord> commitRecordsPartial() {
        return commitRecordsPartial(false);
    }
    public List<CommitRecord> commitRecordsPartial(Boolean returnSuccess) {
        CommitRecord errRec;
        List<CommitRecord> dbErrors = new List<CommitRecord>();
        List<SObject> lRecInsert = new List<SObject>();
        List<SObject> lRecUpdate = new List<SObject>();
        List<SObject> lRecDelete = new List<SObject>();

        for (String stype : commitOrderList) {
            mapRelationship.get(stype).createRelationship();
            //
            lRecInsert = mapRecordsInsert.get(stype);

            if (!lRecInsert.isEmpty()) {
                Integer iIns = 0;

                //Checks if success
                for (Database.SaveResult osr : Database.insert(lRecInsert, false)) {
                    if (returnSuccess) {
                        dbErrors.add(
                            new CommitRecord(lRecInsert.get(iIns).clone(true, true, true, true), osr, false)
                        );
                    } else {
                        if (!osr.isSuccess()) {
                            dbErrors.add(
                                new CommitRecord(lRecInsert.get(iIns).clone(true, true, true, true), osr, false)
                            );
                        }
                    }

                    iIns++;
                }
            }

            //Update
            lRecUpdate = mapRecordsUpdate.get(stype);

            if (!lRecUpdate.isEmpty()) {
                Integer iUpd = 0;

                //Checks if success
                for (Database.SaveResult osr : Database.update(lRecUpdate, false)) {
                    if (returnSuccess) {
                        dbErrors.add(
                            new CommitRecord(lRecUpdate.get(iUpd).clone(true, true, true, true), osr, true)
                        );
                    } else {
                        if (!osr.isSuccess()) {
                            dbErrors.add(
                                new CommitRecord(lRecUpdate.get(iUpd).clone(true, true, true, true), osr, true)
                            );
                        }
                    }

                    iUpd++;
                }
            }

            //Delete
            lRecDelete = mapRemove.get(stype);

            if (!lRecDelete.isEmpty()) {
                Integer iDel = 0;

                //Checks if success
                for (Database.DeleteResult osr : Database.delete(lRecDelete, false)) {
                    if (returnSuccess) {
                        dbErrors.add(
                            new CommitRecord(lRecDelete.get(iDel).clone(true, true, true, true), osr)
                        );
                    } else {
                        if (!osr.isSuccess()) {
                            dbErrors.add(
                                new CommitRecord(lRecDelete.get(iDel).clone(true, true, true, true), osr)
                            );
                        }
                    }

                    iDel++;
                }
            }
        }

        //Clears map and recreates a new set
        instantiate();
        return dbErrors;
    }
    /**
     * @description instantiates handler
     */
    @TestVisible
    private void instantiate() {
        mapRecordsInsert = new Map<String, List<SObject>>();
        mapRecordsUpdate = new Map<String, List<SObject>>();
        mapRemove = new Map<String, List<SObject>>();
        mapRelationship = new Map<String, Records>();
        commitOrderList = new List<String>();

        try {
            if (!lCommitOrder.isEmpty()) {
                for (Schema.sObjectType cmdt : lCommitOrder) {
                    String stype = cmdt.getDescribe().getName();
                    commitOrderList.add(stype);
                    mapRelationship.put(stype, new Records());
                    mapRecordsInsert.put(stype, new List<SObject>());
                    mapRecordsUpdate.put(stype, new List<SObject>());
                    mapRemove.put(stype, new List<SObject>());
                }
            }
        } catch (Exception e) {
            throw new BaseClassException(e.getMessage());
        }
    }
    /**
     * @description performs validation on Commit order
     * @param       sobj            [description]
     * @return                      [description]
     */
    private Boolean validate(SObject sobj) {
        if (commitOrderList == null || commitOrderList.isEmpty()) {
            throw new BaseClassException('Specify Commit Order: initialize[Schema.sObjectType]');
        } else {
            Set<String> stCommits = new Set<String>(commitOrderList);
            String stype = sobj.getSObjectType().getDescribe().getName();

            if (!stCommits.contains(stype)) {
                String sMsg = String.format('Missing Schema.sObjectType ({0}) in Commit Order:',
                                            new LIST<String> {stype});
                throw new BaseClassException(sMsg);
            }
        }

        return true;
    }
    /**
     * @description private class to help manage relationship
     */
    private class Records {
        private List<Record> mRecords = new List<Record>();
        public void createRelationship() {
            for (Record oRec : mRecords) {
                oRec.createRelation();
            }
        }
        public void add(SObject record, Schema.sObjectField relatedToField, SObject relatedTo) {
            // Relationship to resolve
            Record rec = new Record();
            rec.record = record;
            rec.relatedField = relatedToField;
            rec.parentRecord = relatedTo;
            mRecords.add(rec);
        }
    }
    @TestVisible
    private class Record {
        public SObject record {get; set;}
        public Schema.SObjectField relatedField {get; set;}
        public SObject parentRecord {get; set;}
        public void createRelation() {
            record.put(relatedField, parentRecord.Id);
        }
    }
    /**
     * @description public class to return partial commit records
     */
    public class CommitRecord {
        public SObject record {get; set;}
        public List<Database.Error> errors {get; set;}
        private Boolean isSuccessS = false;
        private Boolean isUpdateS = false;
        public Boolean getIsUpdate() {
            return isUpdateS;
        }
        public Boolean getIsSuccess() {
            return isSuccessS;
        }
        public CommitRecord(SObject rec, Database.SaveResult sr, Boolean isUpd) {
            this.record = rec;
            this.isUpdateS = isUpd;

            if (sr != null) {
                this.isSuccessS = sr.isSuccess();
                errors = sr.getErrors();
            }
        }
        public CommitRecord(SObject rec, Database.DeleteResult dr) {
            this.record = rec;

            if (dr != null) {
                this.isSuccessS = dr.isSuccess();
                errors = dr.getErrors();
            }
        }
    }
    public class BaseClassException extends Exception {}
}