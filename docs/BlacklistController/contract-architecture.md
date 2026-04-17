# Blacklist Controller Contract Architecture

### 1. Overview

The **BlacklistController** is an independent controller contract designed for **SolvBTC**'s blacklist capabilities. Its core objective is to decouple blacklist operations from the business contract, establishing a standardized risk control execution mechanism through an independent permission model and blacklist quota limits.

It serves as a bridge between the risk control execution layer and the asset state layer (SolvBTC).

***

### 2. Scope and Usage Context

BlacklistController is designed to provide controlled blacklist management for **risk control teams and automated security systems**, including:

* Rapid response to security incidents (blacklisting suspicious addresses)
* Tiered authorization for risk control operators (separation of Setter and Remover duties)
* Limiting the impact range of individual operators (via quota limits)
* Auditing all blacklist modification operations

#### 2.1 Architecture Overview

The controller acts as the `blacklistManager` for SolvBTC, responsible for validating permissions and quotas. Only calls initiated through the controller can modify the blacklist state in SolvBTC.

* **Admin**: Responsible for global configuration and role authorization.
* **Blacklist Setter**: Responsible for execution of blacklisting, subject to quota limits.
* **Blacklist Remover**: Responsible for execution of unblacklisting, not subject to quota limits.
* **SolvBTC**: Asset contract, maintaining the final blacklist state.

***

### 3. Blacklist Controller Contract

BlacklistController.sol is the logic contract responsible for permission validation and quota management.

Key responsibilities include:
* Maintaining a whitelist registry for Blacklist Setters and Blacklist Removers
* Enforcing a blacklist quota (`maxBlacklistCount`) for each Setter
* Invoking blacklist modification interfaces on SolvBTC
* Providing default quota configurations to simplify the Setter authorization process

***

### 4. Quota and Role Model

The contract splits risk control permissions into two complementary roles to reduce single-point-of-failure risks:

* **Blacklist Setter (Executioner)**:
    * Authorized with `blacklist(target)` permission.
    * Each Setter has an independent `maxBlacklistCount` (maximum blacklist attempts) and `usedBlacklistCount` (consumed quota).
    * Once the quota is exhausted, the Setter cannot perform further blacklisting until the Admin re-authorizes or increases the quota.
* **Blacklist Remover (Reverser)**:
    * Authorized with `unblacklist(target)` permission.
    * Not subject to count quotas but must be explicitly authorized.

**Quota Management and Recovery:**
Unblacklisting does not automatically restore a Setter's consumed quota. The Admin can manually reset or adjust a Setter's consumed quota via `grantBlacklistSetter` by explicitly providing the desired `usedBlacklistCount`. This allows the Admin to either preserve, reset, or precisely adjust the historical consumption of an operator.

***

### 5. Interaction with SolvBTC

BlacklistController does not persist the blacklist registry itself; instead, it interacts with SolvBTC through interfaces:

* **Permission Prerequisite**: The SolvBTC contract must set the controller address as its `blacklistManager` via `updateBlacklistManager`.
* **Execution Logic**:
    * Before blacklisting, the controller checks the status via `solvBTC().isBlacklisted(target)`.
    * During blacklisting, it calls `solvBTC().addBlacklist(target)`.
    * During unblacklisting, it calls `solvBTC().removeBlacklist(target)`.

This design ensures a single source of truth for state while allowing flexible permission logic.

***

### 6. Execution Flow

Blacklist operations are executed as single on-chain transactions with strict permission and state checks.

**Blacklisting Flow (Blacklist):**
1. An authorized Setter calls `blacklist(target)`.
2. The controller validates that `target` is a valid address and not already blacklisted.
3. The controller verifies that the Setter's `usedBlacklistCount` has not reached its `maxBlacklistCount`.
4. The controller calls `solvBTC().addBlacklist(target)`.
5. The Setter's `usedBlacklistCount` is incremented.
6. `BlacklistExecuted` is emitted.

**Unblacklisting Flow (Unblacklist):**
1. An authorized Remover calls `unblacklist(target)`.
2. The controller validates that `target` is currently blacklisted.
3. The controller calls `solvBTC().removeBlacklist(target)`.
4. `UnblacklistExecuted` is emitted.

***

### 7. Risk Management Pattern

In a typical risk control operational flow:

1. **Detection Phase**: Monitoring systems detect suspicious address activity.
2. **Execution Phase**: A pre-authorized Setter (e.g., an automated bot or first-line responder) calls `blacklist` to lock the assets rapidly.
3. **Investigation Phase**: The security audit team intervenes to investigate the address background.
4. **Resolution Phase**: If it's a false positive, a senior manager with Remover permissions calls `unblacklist`. If confirmed as an attack, the blacklist status is maintained.

***

### 8. Governance and Authorization

The Admin manages all business parameters and emergency controls:

* Authorizing/revoking Setter and Remover roles.
* Configuring personalized quotas for each Setter or applying the system-wide global default quota (`defaultMaxBlacklistCount`).
* Managing Admin permission transfers (two-step `transferAdmin` / `acceptAdmin`).

The Admin does not participate in individual blacklist/unblacklist execution, focusing instead on top-level governance of "who can operate" and "how many times."

***

### 9. Observability and Events

The contract records all key operations via rich events to facilitate off-chain auditing and monitoring:

* `BlacklistExecuted`: Records the blacklisting action, including the executor, target, and latest quota consumption.
* `UnblacklistExecuted`: Records the unblacklisting action.
* `BlacklistSetterGranted` / `BlacklistSetterRevoked`: Records changes to Setter permissions and quotas.
* `BlacklistRemoverGranted` / `BlacklistRemoverRevoked`: Records changes to Remover permissions.
* `DefaultMaxBlacklistCountUpdated`: Records modifications to the global default quota.

By subscribing to these events, risk control dashboards can reflect the current asset lock status and operator quota balances in real-time.
