/**
 * Prompt especializado para análise de exames médicos com IA
 *
 * Este prompt é utilizado pelo GPT-4 Vision para analisar imagens de exames
 * e gerar análise com triagem automática de urgência.
 *
 * FLUXO:
 * - NÃO URGENTE (normal/mild_alteration): resultado liberado imediatamente ao paciente
 * - URGENTE (needs_review/critical): encaminhado para revisão médica
 */

export const EXAM_ANALYSIS_SYSTEM_PROMPT = `Você é um assistente de análise de exames médicos. Sua função é auxiliar o médico gerando uma análise preliminar.

## REGRAS OBRIGATÓRIAS:

1. NUNCA forneça diagnóstico definitivo
2. NUNCA sugira tratamento ou medicação
3. Use SEMPRE linguagem condicional e segura
4. O texto "patient_summary" será lido pelo PACIENTE - seja claro e acolhedor
5. O texto "technical_notes" é apenas para o MÉDICO - pode ser técnico

## LINGUAGEM SEGURA (use expressões como):
- "Valores dentro dos parâmetros esperados"
- "Sugere-se acompanhamento"
- "Achado que merece avaliação médica"
- "Recomenda-se correlacionar clinicamente"
- "Considerar avaliação complementar"

## LINGUAGEM PROIBIDA (nunca use):
- "Você tem..."
- "Diagnóstico de..."
- "Isso indica que..."
- "Tome..." / "Use..."
- Qualquer afirmação categórica sobre doenças

## FORMATO DE RESPOSTA (JSON estrito):

Responda APENAS com um JSON válido, sem texto adicional:

{
  "suggested_status": "normal" | "mild_alteration" | "needs_review" | "critical",
  "triage": "urgent" | "non_urgent",
  "triage_reason": "Breve explicação do motivo da classificação de urgência",
  "patient_summary": "Texto claro e acolhedor para o paciente (máx 200 palavras)",
  "technical_notes": "Observações técnicas para o médico (valores, medidas, achados)",
  "confidence": 0.0 a 1.0,
  "flags": ["lista", "de", "alertas", "se houver"],
  "exam_type_detected": "tipo de exame identificado"
}

## CRITÉRIOS DE TRIAGEM (triage):

- **non_urgent**: Status "normal" ou "mild_alteration" — resultado será liberado diretamente ao paciente
- **urgent**: Status "needs_review" ou "critical" — exame será encaminhado para revisão médica presencial
- Na dúvida, classifique como "urgent" (é mais seguro)

## CRITÉRIOS DE STATUS:

- **normal**: Todos valores/achados dentro da referência, sem alterações
- **mild_alteration**: Pequenas alterações que merecem acompanhamento, mas não são urgentes
- **needs_review**: Alterações significativas que necessitam consulta médica presencial
- **critical**: Achados que requerem atenção urgente (valores muito fora do normal, massas suspeitas, etc)

## FLAGS COMUNS:
- "out_of_range_value" - Valor fora da referência
- "follow_up_recommended" - Recomenda acompanhamento
- "urgent_attention" - Atenção urgente necessária
- "compare_with_previous" - Comparar com exames anteriores
- "lifestyle_impact" - Pode ser relacionado a estilo de vida
- "medication_related" - Pode ser relacionado a medicação

## EXEMPLOS DE RESPOSTAS:

Exemplo 1 - Hemograma normal (NÃO URGENTE - resultado liberado ao paciente):
{
  "suggested_status": "normal",
  "triage": "non_urgent",
  "triage_reason": "Todos os valores dentro dos parâmetros normais",
  "patient_summary": "Seu hemograma apresenta valores dentro dos parâmetros esperados. Hemoglobina, leucócitos e plaquetas estão em níveis adequados para sua faixa etária. Continue mantendo seus hábitos saudáveis.",
  "technical_notes": "Hb: 14.2 g/dL (ref: 12-16), Leucócitos: 7.500/mm³ (ref: 4.000-11.000), Plaquetas: 250.000/mm³ (ref: 150.000-400.000). Todos os parâmetros dentro da normalidade.",
  "confidence": 0.92,
  "flags": [],
  "exam_type_detected": "Hemograma completo"
}

Exemplo 2 - Ultrassom com achado (URGENTE - encaminhado ao médico):
{
  "suggested_status": "needs_review",
  "triage": "urgent",
  "triage_reason": "Achado hepático que necessita avaliação médica presencial",
  "patient_summary": "Exame apresenta alteração na região hepática que merece avaliação médica. Recomenda-se agendar consulta para análise detalhada e definição de conduta adequada ao seu caso.",
  "technical_notes": "Imagem sugere esteatose hepática grau I. Padrão ecográfico levemente heterogêneo em lobo direito. Dimensões normais. Vias biliares pérvias.",
  "confidence": 0.78,
  "flags": ["liver_finding", "follow_up_recommended", "lifestyle_impact"],
  "exam_type_detected": "Ultrassonografia de abdome"
}

Exemplo 3 - Glicemia alterada (NÃO URGENTE - alteração leve, resultado liberado):
{
  "suggested_status": "mild_alteration",
  "triage": "non_urgent",
  "triage_reason": "Alteração leve compatível com acompanhamento ambulatorial",
  "patient_summary": "A glicemia em jejum apresenta valor levemente acima do esperado. Isso merece acompanhamento e pode estar relacionado à alimentação ou estilo de vida. Converse com seu médico sobre as melhores orientações para seu caso.",
  "technical_notes": "Glicemia de jejum: 112 mg/dL (ref: 70-99). Valor compatível com pré-diabetes (100-125 mg/dL). Sugerir HbA1c para avaliação complementar.",
  "confidence": 0.85,
  "flags": ["out_of_range_value", "lifestyle_impact", "follow_up_recommended"],
  "exam_type_detected": "Glicemia de jejum"
}`;

export const EXAM_ANALYSIS_USER_PROMPT = `Por favor, analise este exame/documento médico e forneça uma análise estruturada seguindo o formato JSON especificado.

Lembre-se:
1. Seja objetivo e profissional nas notas técnicas
2. Seja acolhedor e claro no resumo para o paciente
3. Classifique corretamente a urgência (normal, mild_alteration, needs_review, critical)
4. Liste todas as flags relevantes
5. Responda APENAS com JSON válido`;

/**
 * Constrói prompt customizado com instruções do ExamType configurado pela clínica.
 * Se não houver ExamType, retorna o prompt padrão.
 */
export function buildUserPromptWithExamType(examTypeConfig?: {
  name: string;
  urgencyKeywords: string[];
  urgencyInstructions?: string | null;
  referenceValues?: any;
  requiresDoctorReview: boolean;
} | null): string {
  if (!examTypeConfig) {
    return EXAM_ANALYSIS_USER_PROMPT;
  }

  let customPrompt = EXAM_ANALYSIS_USER_PROMPT;

  customPrompt += `\n\n## CONFIGURAÇÃO DO TIPO DE EXAME: ${examTypeConfig.name}`;

  if (examTypeConfig.urgencyInstructions) {
    customPrompt += `\n\n### Instruções de urgência da clínica:\n${examTypeConfig.urgencyInstructions}`;
  }

  if (examTypeConfig.urgencyKeywords.length > 0) {
    customPrompt += `\n\n### Palavras-chave de urgência (se identificar alguma, considere triage "urgent"):\n${examTypeConfig.urgencyKeywords.join(', ')}`;
  }

  if (examTypeConfig.referenceValues) {
    customPrompt += `\n\n### Valores de referência configurados:\n${JSON.stringify(examTypeConfig.referenceValues, null, 2)}`;
  }

  if (examTypeConfig.requiresDoctorReview) {
    customPrompt += `\n\n### ATENÇÃO: Este tipo de exame SEMPRE requer revisão médica. Classifique como triage "urgent" independentemente dos achados.`;
  }

  return customPrompt;
}

/**
 * Prompt para quando a IA não consegue analisar
 */
export const EXAM_ANALYSIS_FALLBACK = {
  suggested_status: 'needs_review',
  triage: 'urgent' as const,
  triage_reason: 'Análise automática não disponível - revisão manual necessária.',
  patient_summary: 'Este exame será analisado pela equipe médica. Aguarde a liberação do resultado.',
  technical_notes: 'Análise automática não foi possível. Revisão manual necessária.',
  confidence: 0,
  flags: ['manual_review_required'],
  exam_type_detected: 'Não identificado',
};

/**
 * Mapeia o status sugerido para o enum do Prisma
 */
export function mapSuggestedStatusToEnum(status: string): string {
  const mapping: Record<string, string> = {
    'normal': 'NORMAL',
    'mild_alteration': 'MILD_ALTERATION',
    'needs_review': 'NEEDS_REVIEW',
    'critical': 'CRITICAL',
  };
  return mapping[status] || 'NEEDS_REVIEW';
}

/**
 * Valida e sanitiza a resposta da IA
 */
export function validateAiResponse(response: unknown): {
  suggested_status: string;
  triage: string;
  triage_reason: string;
  patient_summary: string;
  technical_notes: string;
  confidence: number;
  flags: string[];
  exam_type_detected: string;
} {
  const defaultResponse = EXAM_ANALYSIS_FALLBACK;

  if (!response || typeof response !== 'object') {
    return defaultResponse;
  }

  const r = response as Record<string, unknown>;

  return {
    suggested_status: typeof r.suggested_status === 'string'
      ? r.suggested_status
      : defaultResponse.suggested_status,
    triage: typeof r.triage === 'string' && ['urgent', 'non_urgent'].includes(r.triage)
      ? r.triage
      : defaultResponse.triage,
    triage_reason: typeof r.triage_reason === 'string'
      ? r.triage_reason.slice(0, 500)
      : defaultResponse.triage_reason,
    patient_summary: typeof r.patient_summary === 'string'
      ? r.patient_summary.slice(0, 2000)
      : defaultResponse.patient_summary,
    technical_notes: typeof r.technical_notes === 'string'
      ? r.technical_notes.slice(0, 5000)
      : defaultResponse.technical_notes,
    confidence: typeof r.confidence === 'number' && r.confidence >= 0 && r.confidence <= 1
      ? r.confidence
      : defaultResponse.confidence,
    flags: Array.isArray(r.flags)
      ? r.flags.filter((f): f is string => typeof f === 'string').slice(0, 10)
      : defaultResponse.flags,
    exam_type_detected: typeof r.exam_type_detected === 'string'
      ? r.exam_type_detected
      : defaultResponse.exam_type_detected,
  };
}

/**
 * Determina a triagem de urgência baseado na resposta validada da IA.
 * Regras:
 * - critical → sempre URGENT
 * - needs_review → sempre URGENT
 * - normal/mild_alteration → NON_URGENT (se IA concordou)
 * - Confiança < 0.5 → URGENT (segurança)
 * - Fallback → URGENT (em caso de dúvida, médico revisa)
 */
export function determineTriageFromAiResponse(validated: ReturnType<typeof validateAiResponse>): {
  isUrgent: boolean;
  triageResult: string;
  triageReason: string;
} {
  // Status critical é sempre urgente
  if (validated.suggested_status === 'critical') {
    return {
      isUrgent: true,
      triageResult: 'URGENT',
      triageReason: validated.triage_reason || 'Status crítico identificado pela IA.',
    };
  }

  // Status needs_review é sempre urgente
  if (validated.suggested_status === 'needs_review') {
    return {
      isUrgent: true,
      triageResult: 'URGENT',
      triageReason: validated.triage_reason || 'Achados que necessitam revisão médica.',
    };
  }

  // Confiança muito baixa → urgente por segurança
  if (validated.confidence < 0.5) {
    return {
      isUrgent: true,
      triageResult: 'URGENT',
      triageReason: 'Confiança da análise insuficiente - encaminhado para revisão médica.',
    };
  }

  // Flag de atenção urgente
  if (validated.flags.includes('urgent_attention')) {
    return {
      isUrgent: true,
      triageResult: 'URGENT',
      triageReason: validated.triage_reason || 'Atenção urgente sinalizada pela análise.',
    };
  }

  // normal ou mild_alteration com confiança adequada → não urgente
  if (validated.suggested_status === 'normal' || validated.suggested_status === 'mild_alteration') {
    return {
      isUrgent: false,
      triageResult: 'NON_URGENT',
      triageReason: validated.triage_reason || 'Resultados dentro dos parâmetros esperados.',
    };
  }

  // Fallback → urgente (segurança)
  return {
    isUrgent: true,
    triageResult: 'URGENT',
    triageReason: validated.triage_reason || 'Classificação indeterminada - encaminhado para revisão.',
  };
}
