import { describe, expect, it } from 'vitest'

import type { ExerciseDetail } from '@/api/types'
import { SVG_TO_DB, exerciseVector, heatmapMix, jointStyle, normalizeVector } from '@/utils/vectors'

const exercise = {
  propulsive_fcsa_contribution_vector: { soleus: 4 },
  engine: {
    propulsive_fcsa_contribution_vector: { soleus: 5 },
    active_tension_exposure_vector: { soleus: 6, gastrocnemius: 3 },
    etu_vector: { soleus: 8, gastrocnemius: 4 },
    muscle_recovery_cost_modifier_vector: { soleus: 0.5, gastrocnemius: 2 },
    joint_load_exposure_vector: { ankle: 0.7 },
  },
} as unknown as ExerciseDetail

describe('exercise visualization math', () => {
  it('derives recovery from active tension and recovery cost', () => {
    expect(exerciseVector(exercise, 'recovery')).toEqual({ soleus: 3, gastrocnemius: 6 })
  })

  it('normalizes each raw value by its own muscle capacity before the display maximum', () => {
    expect(normalizeVector({ soleus: 8, gastrocnemius: 4 }, { soleus: 8, gastrocnemius: 8 })).toEqual({
      soleus: 1,
      gastrocnemius: 0.5,
    })
  })

  it('handles missing capacities and zero vectors without NaN', () => {
    expect(normalizeVector({ soleus: 0, unknown: 4 }, { soleus: 10 })).toEqual({ soleus: 0, unknown: 0 })
  })

  it('uses the documented heatmap exponent, joint scale, and SVG aliases', () => {
    expect(heatmapMix(0)).toBe(12)
    expect(heatmapMix(1)).toBe(100)
    expect(jointStyle(1)).toEqual({ opacity: 1, strokeWidth: 5.5 })
    expect(SVG_TO_DB.anterior_deltoid).toBe('deltoid_anterior')
    expect(SVG_TO_DB.rotator_cuff).toBe('rotator_cuffs')
  })
})
