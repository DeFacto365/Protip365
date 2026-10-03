// Browser preview has no store or billing gate. Native access is separate from user backups.
import React from 'react';
import {create} from 'zustand';
export const useAccess = create(() => ({canWrite: true, hydrated: true, status: 'trial', trialDaysRemaining: 30, refresh: () => {}}));
export function BillingHost() {return null;}
export function AccessSheet(_props: {visible: boolean; onClose: () => void; t: unknown; onMessage: unknown}) {return null;}
