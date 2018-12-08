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
    @TestVisible
    private Map<String, List<SObject>> mapRecordsInsert {get; set;}
    @TestVisible
    private Map<String, List<SObject>> mapRecordsUpdate {get; set;}
    @TestVisible
    private Map<String, List<SObject>> mapRemove {get; set;}
    @TestVisible
    private Map<String, Records> mapRelationship {get; set;}

    @TestVisible
    private Map<String, List<SObject>> mapBulkRecordsTest {get; set;}

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
     * @param lOrder Schema.sObjectType[]
     * @example
     *             List<Schema.sObjectType> {
     *                 Account.sObjectType,
     *                 Contact.sObjectType
     *              }
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
    }
    /**
     * @description Adds a single record
     * @param       sobj
     * @return
     */
    public void push(SObject sobj) {
        push(sobj, null, null);
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
        //system.debug('push method');
        try {
            if (sobj != null && validate(sobj)) {
                stype = sobj.getSObjectType().getDescribe().getName();
                relate(sobj, relatedField, relatedRecord);
                //system.debug('relate method done');
                if (sobj.Id != null) {
                    mapRecordsUpdate.get(stype).add(sobj);
                    //system.debug('mapRecordsUpdate done');
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
    public List<BaseClass.CommitRecord> commitRecords() {
        Savepoint sp = Database.setSavepoint();
        List<BaseClass.CommitRecord> commitRecords = new List<BaseClass.CommitRecord>();
        Boolean isUpd = false;
        List<SObject> lRecInsert = new List<SObject>();
        List<SObject> lRecUpdate = new List<SObject>();
        List<SObject> lRecDelete = new List<SObject>();
        List<SObject> lRecProcessed = new List<SObject>();
        try {
            for (String stype : commitOrderList) {
                //Insert
                mapRelationship.get(stype).createRelationship();
                //
                lRecInsert = mapRecordsInsert.get(stype);

                if (!lRecInsert.isEmpty()) {
                    lRecProcessed = lRecInsert.deepClone();
                    insert lRecInsert;
                    lRecProcessed = new List<SObject>();
                }

                //Update
                lRecUpdate = mapRecordsUpdate.get(stype);

                if (!lRecUpdate.isEmpty()) {
                    isUpd = true;
                    lRecProcessed = lRecUpdate.deepClone();
                    update lRecUpdate;
                    lRecProcessed = new List<SObject>();
                }

                //Delete
                lRecDelete = mapRemove.get(stype);

                if (!lRecDelete.isEmpty()) {
                    lRecProcessed = lRecDelete.deepClone();
                    delete lRecDelete;
                    lRecProcessed = new List<SObject>();
                }
            }
        } catch (System.DmlException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Integer indxFailedRec = e.getDmlIndex(i);
                String errMsg = e.getDmlMessage(i);
                String dmlType = String.valueOf(e.getDmlType(i));
                SObject sobj = lRecProcessed.get(indxFailedRec);
                String stype = sobj.getSObjectType().getDescribe().getName();
                commitRecords.add(
                    new CommitRecord(stype, sobj,
                                     new List<String> {dmlType, errMsg},
                                     isUpd)
                );
            }
            Database.rollback(sp);
        } catch (Exception e) {
            for (SObject sobj : lRecProcessed) {
                String stype = sobj.getSObjectType().getDescribe().getName();
                SObject nSobj = sobj.clone(true, true, true, true);
                String sException = String.valueOf(e);
                commitRecords.add(
                    new CommitRecord(stype, nSobj, new List<String> {'Exception', sException}, isUpd)
                );
            }
            Database.rollback(sp);
        } finally {
            //Clears map and recreates a new set
            instantiate();
        }
        return commitRecords;
    }
    /**
    * @description Performs Partial Save and Commit to Database
    *              clears last saved records
    *              false second parameter to allow partial processing of records on failure
    * @return BaseClass.CommitRecord
    */
    public List<CommitRecord> commitRecordsPartial() {
        return commitRecordsPartial(false, false);
    }
    /**
    * @description Performs Partial Save and Commit to Database
    *              On Error it Returns a list of Records that failed
    *              clears last saved records
    *              false second parameter to allow partial processing of records on failure
    * @return BaseClass.CommitRecord
    */
    public List<CommitRecord> commitRecordsPartial(Boolean returnSuccess) {
        return commitRecordsPartial(returnSuccess, false);
    }
    /**
     * Performs Partial Save and Commit to Database
     *              clears last saved Records
     * @param  returnSuccess True will Return Success Records
     * @param optAllOrNone   Database OptAllOrNone
     * @return               List Of CommitRecords
     */
    public List<CommitRecord> commitRecordsPartial(Boolean returnSuccess, Boolean optAllOrNone) {
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
                for (Database.SaveResult osr : Database.insert(lRecInsert, optAllOrNone)) {
                    if (returnSuccess) {
                        dbErrors.add(
                            new CommitRecord(stype, lRecInsert.get(iIns).clone(true, true, true, true), osr, false)
                        );
                    } else {
                        if (!osr.isSuccess()) {
                            dbErrors.add(
                                new CommitRecord(stype, lRecInsert.get(iIns).clone(true, true, true, true), osr, false)
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
                for (Database.SaveResult osr : Database.update(lRecUpdate, optAllOrNone)) {
                    if (returnSuccess) {
                        dbErrors.add(
                            new CommitRecord(stype, lRecUpdate.get(iUpd).clone(true, true, true, true), osr, true)
                        );
                    } else {
                        if (!osr.isSuccess()) {
                            dbErrors.add(
                                new CommitRecord(stype, lRecUpdate.get(iUpd).clone(true, true, true, true), osr, true)
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
                for (Database.DeleteResult osr : Database.delete(lRecDelete, optAllOrNone)) {
                    if (returnSuccess) {
                        dbErrors.add(
                            new CommitRecord(stype, lRecDelete.get(iDel).clone(true, true, true, true), osr)
                        );
                    } else {
                        if (!osr.isSuccess()) {
                            dbErrors.add(
                                new CommitRecord(stype, lRecDelete.get(iDel).clone(true, true, true, true), osr)
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

        //Priyanka testing
        mapBulkRecordsTest = new Map<String, List<SObject>>();

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
        public String errorType {get; set;}
        public List<String> errorsMsg {get; set;}
        public String sObjectTypeName {get; set;}
        private Boolean isSuccessS = false;
        private Boolean isUpdateS = false;
        /**
         * Determine if Update Call
         * @return Boolean
         */
        public Boolean getIsUpdate() {
            return isUpdateS;
        }
        /**
         * Return if Success Record
         * @return Boolean
         */
        public Boolean getIsSuccess() {
            return isSuccessS;
        }
        public String getErrorType() {
            String sval = '';
            if (errors != null && !errors.isEmpty()) {
                sval = String.valueOf(errors[0].statusCode);
            } else {
                sval = errorType;
            }
            return sval;
        }
        public CommitRecord(SObject rec, List<String> sExlist, Boolean isUpd) {
            this('', rec, sExlist, isUpd);
        }
        public CommitRecord(String sType, SObject rec, List<String> sExlist, Boolean isUpd) {
            errorsMsg = new List<String>();
            this.sObjectTypeName = sType;
            this.record = rec;
            this.isUpdateS = isUpd;
            errorsMsg.addAll(sExlist);
        }
        public CommitRecord(String sType, SObject rec, Database.SaveResult sr, Boolean isUpd) {
            errorsMsg = new List<String>();
            this.sObjectTypeName = sType;
            this.record = rec;
            this.isUpdateS = isUpd;

            if (sr != null) {
                this.isSuccessS = sr.isSuccess();
                errors = sr.getErrors();
                if (errors != null) {
                    for (Database.Error err : errors) {
                        errorsMsg.add(err.getMessage());
                    }
                }

            }
        }
        public CommitRecord(String sType, SObject rec, Database.DeleteResult dr) {
            errorsMsg = new List<String>();
            this.record = rec;
            this.sObjectTypeName = sType;
            if (dr != null) {
                this.isSuccessS = dr.isSuccess();
                errors = dr.getErrors();
                if (errors != null) {
                    for (Database.Error err : errors) {
                        errorsMsg.add(err.getMessage());
                    }
                }
            }
        }
    }
    /**
     * Injects the instance of an existing BaseClass
     * Initialise destroys variable references
     * @param instance BaseClass
     */
    public void setInstance(BaseClass instance) {
        if (instance != null) {
            this.lCommitOrder = instance.lCommitOrder;
            this.commitOrderList = instance.commitOrderList;
            this.mapRecordsInsert = instance.mapRecordsInsert;
            this.mapRecordsUpdate = instance.mapRecordsUpdate;
            this.mapRemove = instance.mapRemove;
            this.mapRelationship = instance.mapRelationship;
        }
    }
    /**
     * Retrieves the instance of this BaseClass
     * @return Instance of BaseClass
     */
    public BaseClass getInstance() {
        return this;
    }
    public class BaseClassException extends Exception {}
}
