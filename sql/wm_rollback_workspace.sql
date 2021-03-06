-- +----------------------------------------------------------------------------+
-- |                          Jeffrey M. Hunter                                 |
-- |                      jhunter@idevelopment.info                             |
-- |                         www.idevelopment.info                              |
-- |----------------------------------------------------------------------------|
-- |      Copyright (c) 1998-2015 Jeffrey M. Hunter. All rights reserved.       |
-- |----------------------------------------------------------------------------|
-- | DATABASE : Oracle                                                          |
-- | FILE     : wm_rollback_workspace.sql                                       |
-- | CLASS    : Workspace Manager                                               |
-- | PURPOSE  : This script will list all workspaces and which workspace is the |
-- |            current workspace. You are then prompted for the name of a      |
-- |            workspace to rollback. This script discards all changes made in |
-- |            the specified workspace to all tables. Any changes made in the  |
-- |            specified workspace since that workspace was created will be    |
-- |            rolled back and will be executed as an autonomous regular       |
-- |            transaction that will be committed when it finishes.            |
-- |                                                                            |
-- |            Only leaf workspaces can be rolled back. That is, a workspace   |
-- |            cannot be rolled back if it has any descendant workspaces.      |
-- |                                                                            |
-- |            Like the RemoveWorkspace procedure, Rollback Workspace deletes  |
-- |            the data in the workspace; however, unlike the RemoveWorkspace  |
-- |            procedure, RollbackWorkspace does not delete the Workspace      |
-- |            Manager workspace structure.                                    |
-- |                                                                            |
-- |            While this procedure is executing, the specified workspace is   |
-- |            frozen in NO_ACCESS mode.                                       |
-- |                                                                            |
-- |            An exception is raised if one or more of the following apply:   |
-- |                                                                            |
-- |                [*] - workspace has any descendant workspaces.              |
-- |                [*] - workspace does not exist.                             |
-- |                [*] - you do not have the privilege to roll back workspace  |
-- |                      or any affected table.                                |
-- |                                                                            |
-- | NOTE     : As with any code, ensure to test this script in a development   |
-- |            environment before attempting to run it in production.          |
-- +----------------------------------------------------------------------------+

SET TERMOUT OFF;
COLUMN current_instance NEW_VALUE current_instance NOPRINT;
SELECT rpad(sys_context('USERENV', 'INSTANCE_NAME'), 17) current_instance
FROM dual;
SET TERMOUT ON;

PROMPT 
PROMPT +------------------------------------------------------------------------+
PROMPT | Report   : Rollback Workspace                                          |
PROMPT | Instance : &current_instance                                           |
PROMPT +------------------------------------------------------------------------+

SET ECHO        OFF
SET FEEDBACK    6
SET HEADING     ON
SET LINESIZE    180
SET PAGESIZE    50000
SET TERMOUT     ON
SET TIMING      OFF
SET TRIMOUT     ON
SET TRIMSPOOL   ON
SET VERIFY      OFF

CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES

COLUMN current_workspace  FORMAT a10        HEADING "Current"
COLUMN owner              FORMAT a20        HEADING "Workspace Owner"
COLUMN workspace          FORMAT a30        HEADING "Workspace Name"
COLUMN createtime         FORMAT a20        HEADING "Create Time"
COLUMN freeze_status      FORMAT a8         HEADING "Freeze|Status"
COLUMN freeze_mode        FORMAT a20        HEADING "Freeze|Mode"

PROMPT 
PROMPT +------------------------------------------------------------------------+
PROMPT | All Workspaces                                                         |
PROMPT +------------------------------------------------------------------------+

SELECT
    CASE  WHEN dbms_wm.getworkspace = workspace THEN '    *'
          ELSE null
    END AS current_workspace
  , owner
  , workspace
  , TO_CHAR(createtime, 'DD-MON-YYYY HH24:MI:SS') createtime
  , freeze_status
  , freeze_mode
FROM
    dba_workspaces
ORDER BY
    owner
  , workspace;

PROMPT 
ACCEPT wm_rollback_workspace_name CHAR PROMPT 'Enter name of workspace to rollback: '
PROMPT 

BEGIN
    dbms_wm.rollbackworkspace('&wm_rollback_workspace_name', TRUE);
END;
/

