using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using InfinityInfo.DataEntities;
using System.Data.OleDb;
using System.Data;

namespace Entities.InstallExtensions
{
    [Flags]
    public enum SchemaUpdateOptions
    {
        None = 0,
        UpdateFields = 1,
        UpdateChildEntities = 2,
        UpdateReferenceEntities = 4,
        UpdateAll = UpdateFields | UpdateReferenceEntities | UpdateChildEntities,
        RemoveFields = 8,
        UpdateAndRemove = UpdateAll | RemoveFields,
        DropTable = 16
    }
}
