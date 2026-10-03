import React, { useState } from 'react';
import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { settingsRepo } from '../data/repositories';
import { Chip } from './components';
import { Text } from './typography';
import { useTokens } from './tokens';
import { useWriteAccess } from './WriteAccess';
export function EmployerTipDefaults({ employerId }: { employerId: string }) {
  const { t: tr } = useTranslation();
  const { t } = useTokens();
  const { requireWrite } = useWriteAccess();
  const [method, setMethod] = useState(
    () => settingsRepo.get(`tipDefault:${employerId}`) ?? 'direct'
  );
  return (
    <View style={{ marginVertical: 16, gap: 8 }}>
      <Text style={{ color: t.ink, fontSize: 16 }}>{tr('redesign.defaults')}</Text>
      <Text style={{ color: t.dim }}>{tr('redesign.defaultsHint')}</Text>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
        {(['direct', 'pooled', 'mixed'] as const).map((m) => (
          <Chip
            key={m}
            label={tr(`complete.tipMethods.${m}`)}
            selected={m === method}
            onPress={() => {
              if (requireWrite()) {
                settingsRepo.set(`tipDefault:${employerId}`, m);
                setMethod(m);
              }
            }}
          />
        ))}
      </View>
    </View>
  );
}
