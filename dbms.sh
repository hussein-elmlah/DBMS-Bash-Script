#! /usr/bin/bash
shopt -s extglob
export LC_COLLATE=C

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
    if [ -z "$dbName" ]; then
        echo "Database name cannot be empty. Aborting Database connect."
    elif [ -d "$dbPath" ]; then
        currentDb="$dbPath"
        echo "Connected to database '$dbName'."
        runSubMenu
    else
        echo "Database '$dbName' not found."
    fi
}

# Function to drop a database
function dropDatabase() {
    read -p "Enter the database name to drop: " dbName
    dbPath="$DATABASE_DIR/$dbName"
    if [ -z "$dbName" ]; then
        echo "Database name cannot be empty. Aborting Database drop."
    elif [ -d "$dbPath" ]; then
        rm -r "$dbPath"
        echo "Database '$dbName' dropped successfully."
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

    # Check if table already exists
    if [[ -f "$currentDb/$tableName" ]]; then
      echo "Table $tableName already exists."
    else
      # Input number of columns
      read -p "Enter number of columns: " columns

      # Create table directory
      mkdir -p "$currentDb/$tableName"

      # Create metadata file for table
      touch "$currentDb/$tableName/metadata"

      # Create data file for table              
      touch "$currentDb/$tableName/data"

      # Loop through columns
      columnNames=()
      for ((i = 1; i <= columns; i++)); do
        # Input column name
        read -p "Enter Column $i Name: " colName
        columnNames+=("$colName")

        # Input data type
        read -p "Select Data Type for $colName (int/str/boolean): " datatype

        # Input if column is primary key
        read -p "Is $colName a primary key? (yes/no): " isPrimary

        # Append column info to metadata file
        echo "$colName|$datatype|$isPrimary" >> "$currentDb/$tableName/metadata"
      done

      # Store column names in the first row of the data file with "|"
      echo "${columnNames[*]}" | tr ' ' '|' >> "$currentDb/$tableName/data"


      echo "Table $tableName created successfully."
    fi
  else
    echo "Name validation error."
  fi
} # End createTable function.


# Function to list all tables in the current database
function listTable() {
    echo "listTable function is called."

    cd "$currentDb" || { echo "Error: Could not change to the database directory."; return; }

    # Check if the database is empty
    if [ -z "$(ls -A)" ]; then
        echo "No tables found in the current database."
        return
    fi

    echo "Tables in the current database:"

    for table in *
    do
        if [ -d "${table}" ]; then
            echo "- ${table}"
        fi
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

    # List only directories (tables), not regular files
    for table in "$currentDb"/*; do
        if [ -d "$table" ]; then
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

    if [ -d "$tablePath" ]; then
        rm -r "$tablePath"
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

    # List only directories (tables), not regular files
    for table in "$currentDb"/*; do
        if [ -d "$table" ]; then
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

    if [ -d "$tablePath" ]; then
        echo "Do you want to insert columns or data into columns?"
        select option in "Insert Columns" "Insert Data"; do
            case $option in
                "Insert Columns")
                    read -p "Enter column names separated by commas: " newColumns

                    # Prompt for metadata for each column
                    declare -a metadata=()
                    for column in $(echo "$newColumns" | tr ',' ' '); do
                        while true; do
                            read -p "Enter metadata for $column (int/str/bool): " columnType
                            case $columnType in
                                "int"|"str"|"bool")
                                    break
                                    ;;
                                *)
                                    echo "Invalid column type. Please enter 'int', 'str', or 'bool'."
                                    ;;
                            esac
                        done

                        while true; do
                            read -p "Is $column a primary key? (y/n): " isPrimaryKey
                            case $isPrimaryKey in
                                "y"|"n")
                                    break
                                    ;;
                                *)
                                    echo "Invalid input. Please enter 'y' or 'n'."
                                    ;;
                            esac
                        done

                        metadata+=("$column|$columnType|$isPrimaryKey")
                    done



			# Append column names to the first row of the data file
			existingColumns=$(head -n 1 "$tablePath/data")
			allColumns="$existingColumns|$newColumns"
			echo "$allColumns" > "$tablePath/data"

 		# Append metadata to the metadata file
                    printf "%s\n" "${metadata[@]}" >> "$tablePath/metadata"
                    echo "Columns inserted successfully into table '$tableName'."
                    break
                    ;;
                "Insert Data")
                    # Read column names from the metadata file
                    columns=$(head -n 1 "$tablePath/metadata")

                    # Prompt user for values for each column
                    declare -a values=()
                    for column in $(echo "$columns" | tr ',' ' '); do
                        echo -n "Enter value for $column: "
                        read value
                        values+=("$value")
                    done

                    # Combine values into a comma-separated string
                    valuesString=$(IFS=, ; echo "${values[*]}")

                    # Append values to the data file
                    echo "$valuesString" >> "$tablePath/data"

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

    tablePath="$currentDb/$tableName/data"

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

    tablePath="$currentDb/$tableName/data"

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

# Function to runMainMenu a table
function runMainMenu() {
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
                exit
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done
    done
}

# ================================<< End of (( Main Menu )) >>================================


# ================================<< Start of (( SubMenu )) >>================================

# Function to runSubMenu a table
function runSubMenu() {
        while [ -n "$currentDb" ]; do
        PS3="Choose an option: "
        options=("Create Table" "List Tables" "Drop Table" "Insert Into Table" "Select From Table" "Delete From Table" "Update Table" "Back TO Main Menu" "Quit")
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
                "Back TO Main Menu")
                    currentDb=""
                    return
                    ;;
                "Quit")
                    exit
                    ;;
                *)
                    echo "Invalid option. Please try again."
                    ;;
            esac
        done
    done
}

# ================================<< End of (( SubMenu )) >>================================

# ================================<< (( CALLING MAIN FUNCTION TO RUN THE PROGRAM )) >>================================

runMainMenu
