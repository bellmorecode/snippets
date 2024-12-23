using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using InfinityInfo.DataEntities;
using System.Data.OleDb;
using System.Data;

namespace Entities.InstallExtensions
{
    public static class TableCreator
    {
        public static int CreateDefinition(this DataEntity instance)
        {
            return CreateDefinition(instance, SchemaUpdateOptions.UpdateAll);
        }

        public static int CreateDefinition(this DataEntity instance, SchemaUpdateOptions mode)
        {
            StringBuilder sb1 = new StringBuilder();
            //CREATE TABLE 
            sb1.Append(@"CREATE TABLE ");
            //[ database_name.[ owner ] . | owner. ] table_name 
            sb1.Append(instance.EntityTableName);
            //( { < column_definition > 
            //    | column_name AS computed_column_expression 
            //    | < table_constraint > } [ ,...n ] 
            //)      

            sb1.Append(@" ( ");

            
            //sb1.Append(
            //    String.Join(
            //        " ", 
            //        new string[] { instance.EntityPrimaryKeyFieldName, "VARCHAR(50)" })
            //        );

            string comma = String.Empty;

            foreach (DataField field in instance.FieldMappings)
            {

                sb1.Append(comma);
                comma = ", ";

                string fieldTypeDef = "VARCHAR(50)";

                switch (field.DataType.Name)
                {
                    case "String":
                        StringDataField stringField = field as StringDataField;
                        if (stringField is StringDataField)
                        {
                            if (stringField.MaxLength > 0)
                            {
                                fieldTypeDef = "VARCHAR(" + stringField.MaxLength + ")";
                            }
                        }
                        break;
                    case "DateTime":
                        fieldTypeDef = "DATETIME";
                        break;
                    case "Double":
                        fieldTypeDef = "float";
                        break;
                    case "Int32":
                        fieldTypeDef = "int";
                        break;

                    case "Decimal":
                        fieldTypeDef = "decimal";
                        break;
                    default:
                        break;
                }

                string primaryKeyIndicator = String.Empty;

                if (field.IsPrimaryKey) { primaryKeyIndicator = @"PRIMARY KEY CLUSTERED"; }

                sb1.Append(
                String.Join(
                    " ",
                    new string[] { field.FieldName, fieldTypeDef, primaryKeyIndicator  })
                    );
            }
            
            sb1.Append(@") ");


            try
            {
                using (OleDbConnection cn = new OleDbConnection(instance.ActiveConnectionString))
                {
                    cn.Open();
                    using (OleDbCommand cmd1 = cn.CreateCommand())
                    {
                        cmd1.CommandText = sb1.ToString();
                        cmd1.ExecuteNonQuery();
                    }
                    cn.Close();
                }
            }
            catch (OleDbException ex)
            {
                string exMessage = ex.Message;
                string formattedMessage = String.Format(@"There is already an object named '{0}' in the database.", instance.EntityTableName);
                if (exMessage.Equals(formattedMessage))
                {
                    instance.UpdateDefinition(SchemaUpdateOptions.UpdateFields);
                }
                else
                {
                    throw ex;
                }
            }

            return 0;
        }
    }

    public static class TableUpdater
    {
        
        public static int UpdateDefinition(this DataEntity instance)
        {
            return UpdateDefinition(instance, SchemaUpdateOptions.UpdateAll);
        }

        [Obsolete("This method is obselete", false)]
        public static int UpdateDefinition(this DataEntity instance, SchemaUpdateOptions mode)
        {
            if ((mode & SchemaUpdateOptions.DropTable) == SchemaUpdateOptions.DropTable) { return RemoveDefinition(instance, mode); }

            List<string> existingColNames = new List<string>();
            string checkExistsSelectQuery = String.Format("SELECT TOP 1 * FROM {1}", instance.EntityPrimaryKeyFieldName, instance.EntityTableName);

            try
            {
                using (DataTable dt1 = GetResultsAsDataTable(instance.ActiveConnectionString, checkExistsSelectQuery))
                {
                    DataColumnCollection cols = dt1.Columns;

                    foreach (DataColumn item in cols)
                    {
                        existingColNames.Add(item.ColumnName);
                        Console.WriteLine(item.ColumnName);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                return -1;
            }

            // take list from select statement and cross-reference with items in the entity definition
            


            string[] columnsColection = new string[] { "ADD GlennTestCol1 VarChar(100)" }; //, "ADD COLUMN GlennTestCol2 DateTime"
            string updateSqlStarter = String.Format(@"ALTER TABLE {0} ", instance.EntityTableName);
            StringBuilder sb1 = new StringBuilder(updateSqlStarter);
            //sb1.Append("( ");
            sb1.Append(String.Join(", ", columnsColection));
            //sb1.Append(") ");

            ExecuteSql(instance.ActiveConnectionString, sb1.ToString());

            //ALTER TABLE [ database_name . [ schema_name ] . | schema_name . ] table_name 
            //{ 
            //    ALTER COLUMN column_name 
            //    { 
            //        [ type_schema_name. ] type_name [ ( { precision [ , scale ] 
            //            | max | xml_schema_collection } ) ] 
            //        [ COLLATE collation_name ] 
            //        [ SPARSE | NULL | NOT NULL ] 
            //    | {ADD | DROP } 
            //        { ROWGUIDCOL | PERSISTED | NOT FOR REPLICATION | SPARSE }
            //    } 
            //        | [ WITH { CHECK | NOCHECK } ]

            //    | ADD 
            //    { 
            //        <column_definition>
            //      | <computed_column_definition>
            //      | <table_constraint> 
            //      | <column_set_definition> 
            //    } [ ,...n ]

            //    | DROP 
            //    { 
            //        [ CONSTRAINT ] constraint_name 
            //        [ WITH ( <drop_clustered_constraint_option> [ ,...n ] ) ]
            //        | COLUMN column_name 
            //    } [ ,...n ] 

            return 0;
        }

        private static int RemoveDefinition(this DataEntity instance, SchemaUpdateOptions mode)
        {
            throw new NotImplementedException();
        }

        private static void ExecuteSql(string connectionString, string query)
        {

            using (OleDbConnection cn1 = new OleDbConnection(connectionString))
            {
                cn1.Open();
                using (OleDbCommand cmd1 = cn1.CreateCommand())
                {

                    cmd1.CommandText = query;
                    try
                    {
                        cmd1.ExecuteNonQuery();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(ex.Message);
                    }
                }
                cn1.Close();
            }


        }

        private static DataTable GetResultsAsDataTable(string connectionString, string query)
        {
            DataTable dt1 = new DataTable();

            try
            {
                using (OleDbConnection cn1 = new OleDbConnection(connectionString))
                {
                    cn1.Open();
                    using (OleDbCommand cmd1 = cn1.CreateCommand())
                    {
                        cmd1.CommandText = query;
                        using (OleDbDataAdapter da1 = new OleDbDataAdapter(cmd1))
                        {
                            da1.Fill(dt1);
                        }
                    }
                    cn1.Close();
                }

                return dt1;
            }
            catch (Exception)
            {
                return new DataTable();
            }

        }

       
    }

    #region random thought
    // ICM: remove MergeResultItem and its derivatives.
    // Instead, add Attribute to fields (DataEntity!DataField) in the EntityModel
    // that should be included in the result set rendering.
    // Notes: This removes at least 1 type per data model 
    // that we define and further enables the framework for 
    // configuration via an UI.
    #endregion
}
