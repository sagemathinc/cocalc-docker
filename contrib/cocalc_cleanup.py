#!/usr/bin/python
import psycopg2
import subprocess
import os.path
import uuid
from datetime import datetime, timedelta

# defautl settings
nb_days_inactive = 365  # by default remove accounts inacrtive since one year
endswith_not_removed = '@univ-nantes.fr' # These are professor's addresses that should not be removed (leave blank if not needed)

# utility function
def humanreadablesize( kbsize ):
    units = ['kB', 'MB', 'GB', 'TB']
    index = 0
    while kbsize / 1024 >= 1 and index < 3:
        index += 1
        kbsize = kbsize / 1024

    return str(round(kbsize, 2)) + " " + units[index]

# open connexion
conn = psycopg2.connect(host='/projects/postgres/data/socket', user='smc')

# create a cursor
cur = conn.cursor()

# list of accounts to remove
accounts_to_remove = {}

# get accounts inactive since nb_days_inactive days
# and not from endswith_not_removed email address
print("\nLooking for accounts inactive since at least {} days".format(nb_days_inactive))
cur.execute("SELECT account_id, email_address, last_active from accounts WHERE deleted IS NOT TRUE;")
accounts = cur.fetchall()
for account in accounts:
    age = datetime.now() - account[2]
    if age >= timedelta(nb_days_inactive) and not (account[1] and account[1].endswith(endswith_not_removed)):
        accounts_to_remove[account[0]] = (account[1], age, []) #only keep ids of accounts to remove
print("Total number of accounts : {} ({} inactive)".format(len(accounts), len(accounts_to_remove)))

# now get all active projects
cur.execute("SELECT project_id, title, users  from projects WHERE deleted IS NOT TRUE;")
projects = cur.fetchall()
print("Number of active projects : {}".format(len(projects)))
for project in projects:
    for (k,v) in project[2].items():
        if v['group'] == 'owner' and k in accounts_to_remove.keys():
                accounts_to_remove[k][2].append(project[0])

# now get all deleted projects
cur.execute("SELECT project_id, title, users  from projects WHERE deleted IS TRUE;")
projects = cur.fetchall()
deleted_projects_size = 0
deleted_projects_to_remove = []
for project in projects:
    if os.path.exists("/projects/"+project[0]):
        deleted_projects_size += int(subprocess.check_output(['du','-sk', "/projects/"+project[0]]).split()[0].decode('utf-8'))
        deleted_projects_to_remove.append(project[0])

print("Number of deleted projects : {} ({} not erased)".format(len(projects), len(deleted_projects_to_remove)))

# summary of accounts and projects
if len(accounts_to_remove.values()) > 0:
    print("\nAccounts to mark as deleted :")
else:
    print("\nAccounts to mark as deleted : None")
nb_projects_to_remove = 0
total_size = 0
for account in accounts_to_remove.values():
    account_size = 0
    print("{}, inactive since {} days".format(account[0], account[1].days))
    if len(account[2]) > 0:
        print("\t projects to remove : ", len(account[2]))
        nb_projects_to_remove += len(account[2])
        for project in account[2]:
            account_size += int(subprocess.check_output(['du','-sk', "/projects/"+project]).split()[0].decode('utf-8'))
    print("\t Account size : {}".format(humanreadablesize(account_size)))
    total_size += account_size

print("\nSize of deleted but not erased projects : ", humanreadablesize(deleted_projects_size))
print("\n{} accounts of a least {} days and {} projects will be removed :".format(len(accounts_to_remove.values()), nb_days_inactive, nb_projects_to_remove))
print("Total size of projects to remove : {}".format(humanreadablesize(total_size)))

# now let's ask what we should do
print("\nBlank answers defaults to 'no'")
answer = input("Would you like to erase all files of deleted projects ? [yes/no] ")
if answer == "yes":
    # erase deleted projets directories
    for project in deleted_projects_to_remove:
        print("\t Deleting {}".format("/projects/"+project))
        subprocess.run(['rm','-rf', "/projects/"+project])
    print("Done !")
else :
    print("\t NOT erasing files")

answer = input("\nWould you like to delete old accounts and their projects ? [yes/no] ")
if answer == "yes":
    # marks old accounts and projects as deleted 
    for (k,v) in accounts_to_remove.items():
        print("\t Deleting account {}".format(v[0]))
        cur.execute("SELECT account_id, email_address, deleted from accounts WHERE account_id = %s;", (k,))
        print(cur.fetchone())
        cur.execute("UPDATE accounts SET deleted = %s  WHERE account_id = %s;", (True, k))
        conn.commit()
        for project in account[2]: 
            print("\t\t Deleting project {}".format(project))
            cur.execute("SELECT project_id, deleted from projects WHERE project_id = %s;", (project,))
            print(cur.fetchone())
            cur.execute("UPDATE projects SET deleted = %s  WHERE project_id = %s;", (True, project,))
            conn.commit()
    print("\nProjects marked as deleted. Please run this script once again to erase deleted projects.")
else :
    print("\t NOT deleting accounts and projects")
