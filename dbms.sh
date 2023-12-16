
# ================================<< Start of (( Directory Variables )) >>================================

# Directory to store databases (same as the script file directory)
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
DATABASE_DIR="$SCRIPT_DIR/databases"

# another DATABASE_DIR possible to use (makes databases stored in the user home directory)
# DATABASE_DIR="/home/$(whoami)/Databases/"

# Create the directory if it doesn't exist
mkdir -p "$DATABASE_DIR"

# Variable to track the current database
currentDb=""

# ================================<< End of (( Directory Variables )) >>================================

# ================================<< Start of (( Functions of DBMS )) >>================================

# Function to create a new database
function createDatabase() {
    read -p "Enter the database name: " dbName
    dbPath="$DATABASE_DIR/$dbName"
    if [[ ! $dbName =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid database name. Database names must start with a letter or underscore and only contain letters, numbers, and underscores."
    elif [ -d "$dbPath" ]; then
        echo "Database '$dbName' already exists."
    else
        mkdir "$dbPath"
        echo "Database '$dbName' created successfully."
    fi
}

# Function to list all databases
function listDatabase() {
    echo "Available databases:"
    for db in "$DATABASE_DIR"/*/; do
        echo "- $(basename "${db%/}")"
    done
}

# Function to connect to a database
function connectToDatabase() {
    read -p "Enter the database name: " dbName
    dbPath="$DATABASE_DIR/$dbName"
    if [ -d "$dbPath" ]; then
        currentDb="$dbPath"
        echo "Connected to database '$dbName'."
    else
        echo "Database '$dbName' not found."
    fi
}

# Function to drop a database
function dropDatabase() {
    read -p "Enter the database name to drop: " dbName
    dbPath="$DATABASE_DIR/$dbName"
    if [ -d "$dbPath" ]; then
        rm -r "$dbPath"
        echo "Database '$dbName' dropped successfully."
        currentDb=""
    else
        echo "Database '$dbName' not found."
    fi
}

# Function to create a new table
function createTable() {
    echo "createTable function is called."

  # Input table name
read -p "Enter table name: " tableName

# Validate table name
if [[ $tableName =~ ^[A-Za-z_]{1}[A-Za-z0-9]*$ ]]; then
  # Input database name
  read -p "Enter database name: " dbName

  # Check if table already exists
  if [[ -f "./databases/$dbName/$tableName" ]]; then
    echo "Table $tableName already exists."
  else
    # Input number of columns
    read -p "Enter number of columns: " columns

    # Create table file
    touch "./databases/$dbName/$tableName"

    # Loop through columns
    for ((i = 1; i <= columns; i++)); do
      # Input column name
      read -p "Enter Column $i Name: " colName

      # Input data type
      read -p "Select Data Type for $colName (int/str/boolean): " datatype

      # Input if column is primary key
      read -p "Is $colName a primary key? (yes/no): " isPrimary

      # Append column info to table file
      echo "$colName|$datatype|$isPrimary" >> "./databases/$dbName/$tableName"
    done

    echo "Table $tableName created successfully."
  fi
else
  echo "Name validation error."
fi
} # End createTable function.

# Function to list all tables in the current database
function listTable() {
    echo "listTable function is called."
    DATABASE_DIR="$SCRIPT_DIR/databases"
    cd "$DATABASE_DIR" || { echo "Error: Could not change to the database directory."; return; }
    echo "Tables in the current database:"

    if [ -z "$(sudo ls -A *)" ]
    then
        echo "No tables found in the current database."
        return
    fi

    for table in *
    do
        echo "- ${table}"
    done
} # End listTable function.

# Function to drop a table from the specified database
function dropTable() {
    echo "dropTable function is called."

    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    echo "Tables in the current database:"

    # List only regular files (tables), not directories
    for table in "$currentDb"/*; do
        if [ -f "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    echo -n "Enter the table name to drop: "
    read tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting table drop."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -e "$tablePath" ]; then
        rm "$tablePath"
        echo "Table '$tableName' dropped successfully."
    else
        echo "Table '$tableName' not found in the current database."
    fi
} # End dropTable function




# Function to insert into a table
function insertIntoTable() {
    echo "insertIntoTable function is called."

    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    echo "Tables in the current database:"

    # List only regular files (tables), not directories
    for table in "$currentDb"/*; do
        if [ -f "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    echo -n "Enter the table name to insert into: "
    read tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting insert operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -e "$tablePath" ]; then
        echo "Do you want to insert columns or data into columns?"
        select option in "Insert Columns" "Insert Data"; do
            case $option in
                "Insert Columns")
                    read -p "Enter column names separated by commas: " newColumns
                    existingColumns=$(head -n 1 "$tablePath")
                    allColumns="$existingColumns,$newColumns"
                    echo "$allColumns" > "$tablePath"
                    echo "Columns inserted successfully into table '$tableName'."
                    break
                    ;;
                "Insert Data")
                    # Read column names from the table file
                    columns=$(head -n 1 "$tablePath")

                    # Prompt user for values for each column
                    declare -a values=()
                    for column in $(echo "$columns" | tr ',' ' '); do
                        echo -n "Enter value for $column: "
                        read value
                        values+=("$value")
                    done

                    # Combine values into a comma-separated string
                    valuesString=$(IFS=, ; echo "${values[*]}")

                    # Append values to the table file
                    echo "$valuesString" >> "$tablePath"

                    echo "Values inserted successfully into table '$tableName'."
                    break
                    ;;
                *)
                    echo "Invalid option. Please select again."
                    ;;
            esac
        done
    else
        echo "Table '$tableName' not found in the current database."
    fi
} # End insertIntoTable function




# Function to select from a table
function selectFromTable() {
    echo "selectFromTable function is called."

    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    echo "Tables in the current database:"

    # List only regular files (tables), not directories
    for table in "$currentDb"/*; do
        if [ -f "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    echo -n "Enter the table name to select from: "
    read tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting select operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -e "$tablePath" ]; then
        # Read column names from the table file
        columns=$(head -n 1 "$tablePath")

        # Display column names
        echo "Columns in table '$tableName':"
        IFS=',' read -ra columnArray <<< "$columns"
        for ((i=0; i<${#columnArray[@]}; i++)); do
            echo "$i - ${columnArray[$i]}"
        done

        # Prompt user for column selection
        read -p "Enter column numbers (comma-separated) or 'all' for all columns: " selectedColumns

        # Parse selected columns
        if [ "$selectedColumns" == "all" ]; then
            selectedColumns="*"
        else
            IFS=',' read -ra selectedArray <<< "$selectedColumns"
            selectedColumns=""
            for index in "${selectedArray[@]}"; do
                selectedColumns+="${columnArray[$index]},"
            done
            # Remove trailing comma
            selectedColumns=${selectedColumns%,}
        fi

        # Prompt user for conditions
        read -p "Enter conditions for selection (Press Enter if none): " conditions

        # Perform selection based on conditions and selected columns
        if [ -z "$conditions" ]; then
            awk -F, -v cols="$selectedColumns" 'NR>1 {OFS=","} {print $cols}' "$tablePath"
        else
            awk -F, -v cols="$selectedColumns" -v conditions="$conditions" 'NR==1 || $0~conditions {OFS=","} {print $cols}' "$tablePath"
        fi | tail -n +2  # Display values only, excluding the header

        echo "Selection from table '$tableName' completed."
    else
        echo "Table '$tableName' not found in the current database."
    fi
} # End selectFromTable function




# Function to delete from a table
function deleteFromTable() {
    echo "deleteFromTable function is called."

    if [ -z "$currentDb" ]; then
        echo "No database selected. Please connect to a database first."
        return
    fi

    echo "Tables in the current database:"

    # List only regular files (tables), not directories
    for table in "$currentDb"/*; do
        if [ -f "$table" ]; then
            echo "- $(basename "$table")"
        fi
    done

    echo -n "Enter the table name to delete from: "
    read tableName

    if [ -z "$tableName" ]; then
        echo "Table name cannot be empty. Aborting delete operation."
        return
    fi

    tablePath="$currentDb/$tableName"

    if [ -e "$tablePath" ]; then
        # Read column names from the table file
        columns=$(head -n 1 "$tablePath")

        # Display column names
        echo "Columns in table '$tableName':"
        IFS=',' read -ra columnArray <<< "$columns"
        for ((i=0; i<${#columnArray[@]}; i++)); do
            echo "$i - ${columnArray[$i]}"
        done

        # Prompt user for conditions
        read -p "Enter conditions for deletion: " conditions

        # Perform deletion based on conditions
        if [ -z "$conditions" ]; then
            echo "Deleting all rows from table '$tableName'."
            > "$tablePath"  # Clear the table file
        else
            awk -F, -v conditions="$conditions" '$0 !~ conditions' "$tablePath" > "$tablePath.tmp"
            mv "$tablePath.tmp" "$tablePath"
            echo "Rows deleted from table '$tableName' based on the specified conditions."
        fi
    else
        echo "Table '$tableName' not found in the current database."
    fi
} # End deleteFromTable function


# Function to update a table
function updateTable() {
    echo "updateTable function is called."
}

# ================================<< End of (( Functions of DBMS )) >>================================

# ================================<< Start of (( Main Menu )) >>================================

while true; do
    PS3="Choose an option: "
    options=("Create Database" "List Databases" "Connect To Database" "Drop Database" "Quit")
    select opt in "${options[@]}"; do
        case $opt in
            "Create Database")
                createDatabase
                break
                ;;
            "List Databases")
                listDatabase
                break
                ;;
            "Connect To Database")
                connectToDatabase
                break
                ;;
            "Drop Database")
                dropDatabase
                break
                ;;
            "Quit")
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done

# ================================<< Start of (( SubMenu )) >>================================

    while [ -n "$currentDb" ]; do
        PS3="Choose an option: "
        options=("Create Table" "List Tables" "Drop Table" "Insert Into Table" "Select From Table" "Delete From Table" "Update Table" "Quit")
        select opt in "${options[@]}"; do
            case $opt in
                "Create Table")
                    createTable
                    break
                    ;;
                "List Tables")
                    listTable
                    break
                    ;;
                "Drop Table")
                    dropTable
                    break
                    ;;
                "Insert Into Table")
                    insertIntoTable
                    break
                    ;;
                "Select From Table")
                    selectFromTable
                    break
                    ;;
                "Delete From Table")
                    deleteFromTable
                    break
                    ;;
                "Update Table")
                    updateTable
                    break
                    ;;
                "Quit")
                    echo "Exiting..."
                    exit 0
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
            esac
        done
    done

# ================================<< End of (( SubMenu )) >>================================

done

# ================================<< End of (( Main Menu )) >>================================
