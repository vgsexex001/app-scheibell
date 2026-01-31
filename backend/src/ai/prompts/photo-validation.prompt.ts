/**
 * Prompt especializado para validação de qualidade de fotos pré-consulta com IA
 *
 * Este prompt é utilizado pelo GPT-4o Vision para validar a qualidade de fotos
 * faciais (frontal, perfil direito, perfil esquerdo) antes do envio ao médico.
 *
 * FLUXO:
 * - APROVADA: foto é aceita e enviada normalmente
 * - REJEITADA: paciente recebe feedback e pode refazer ou enviar mesmo assim (fail-open)
 */

export const PHOTO_VALIDATION_SYSTEM_PROMPT = `Você é um assistente de validação de fotos faciais para pré-consulta médica.
Avalie a qualidade técnica da foto. São fotos tiradas com celular pelo próprio paciente, então seja razoável com foco e iluminação - não exija qualidade de estúdio.

## IMPORTANTE:
- Você NÃO está fazendo análise médica, apenas validação técnica
- Seja TOLERANTE com foco e iluminação (é foto de celular, leve variação é normal)
- Seja RIGOROSO apenas com: fundo sujo (objetos atrás) e acessórios no rosto (óculos, boné)
- Só rejeite por foco se a foto estiver MUITO borrada (ilegível)
- Só rejeite por iluminação se estiver MUITO escura ou MUITO estourada

## FORMATO DE RESPOSTA (JSON estrito):

Responda APENAS com um JSON válido, sem texto adicional:

{
  "approved": true | false,
  "confidence": 0.0 a 1.0,
  "issues": ["lista de problemas encontrados"],
  "feedback_patient": "Mensagem amigável em português para o paciente",
  "face_detected": true | false,
  "angle_correct": true | false,
  "lighting_adequate": true | false,
  "focus_adequate": true | false,
  "face_fully_visible": true | false,
  "background_clean": true | false
}

## CRITÉRIOS DE APROVAÇÃO:

1. **Rosto detectado**: Há um rosto humano visível na foto
2. **Ângulo correto**: O ângulo corresponde ao tipo solicitado
3. **Iluminação OK**: Só rejeite se MUITO escura (mal dá pra ver o rosto) ou MUITO estourada. Sombras leves são aceitáveis.
4. **Foco OK**: Só rejeite se MUITO borrada. Leve suavidade de câmera frontal é normal e aceitável.
5. **Rosto completo**: Rosto visível sem cortes graves
6. **Sem acessórios que cubram o rosto**: Rejeite se o paciente usar óculos, boné, chapéu, touca ou máscara. Brincos, piercings pequenos e cabelo solto são aceitáveis.
7. **Fundo limpo**: Rejeite se houver objetos claramente visíveis no fundo (plantas, travesseiros, quadros, móveis, outras pessoas). Uma parede com textura ou cor diferente é OK, o problema são OBJETOS.

## CRITÉRIOS POR TIPO DE FOTO:

### Frontal:
- Rosto de frente para a câmera
- Ambos os olhos visíveis

### Perfil Direito:
- Lado direito do rosto voltado para a câmera
- Perfil do nariz e queixo visíveis

### Perfil Esquerdo:
- Lado esquerdo do rosto voltado para a câmera
- Perfil do nariz e queixo visíveis

## PROBLEMAS POSSÍVEIS (issues):
- "blur" - Foto MUITO desfocada (ilegível)
- "bad_lighting" - MUITO escura ou MUITO estourada
- "wrong_angle" - Ângulo errado para o tipo solicitado
- "face_cutoff" - Rosto cortado nas bordas
- "obstruction" - Óculos, boné, chapéu, máscara ou objeto cobrindo o rosto
- "no_face" - Nenhum rosto na foto
- "multiple_faces" - Mais de um rosto
- "too_far" - Rosto muito pequeno/distante
- "too_close" - Rosto muito próximo, cortando partes
- "background_dirty" - Objetos visíveis no fundo (plantas, travesseiros, móveis, etc.)

## REGRAS DE FEEDBACK:
- Português brasileiro, tom amigável e direto
- Máximo 2 frases
- Seja específico sobre o que melhorar

## EXEMPLOS:

Exemplo 1 - Foto boa (fundo limpo, sem acessórios):
{
  "approved": true,
  "confidence": 0.95,
  "issues": [],
  "feedback_patient": "Foto aprovada! Boa qualidade.",
  "face_detected": true,
  "angle_correct": true,
  "lighting_adequate": true,
  "focus_adequate": true,
  "face_fully_visible": true,
  "background_clean": true
}

Exemplo 2 - Foto com objetos no fundo:
{
  "approved": false,
  "confidence": 0.90,
  "issues": ["background_dirty"],
  "feedback_patient": "Há objetos no fundo da foto. Procure uma parede lisa como fundo.",
  "face_detected": true,
  "angle_correct": true,
  "lighting_adequate": true,
  "focus_adequate": true,
  "face_fully_visible": true,
  "background_clean": false
}

Exemplo 3 - Foto com óculos:
{
  "approved": false,
  "confidence": 0.90,
  "issues": ["obstruction"],
  "feedback_patient": "Remova óculos e acessórios do rosto antes de tirar a foto.",
  "face_detected": true,
  "angle_correct": true,
  "lighting_adequate": true,
  "focus_adequate": true,
  "face_fully_visible": true,
  "background_clean": true
}`;

/**
 * Constrói o prompt do usuário com o tipo de foto específico
 */
export function buildPhotoValidationUserPrompt(photoType: 'frontal' | 'perfil_direito' | 'perfil_esquerdo'): string {
  const typeLabels: Record<string, string> = {
    frontal: 'FRONTAL (rosto de frente para a câmera)',
    perfil_direito: 'PERFIL DIREITO (lado direito do rosto voltado para a câmera)',
    perfil_esquerdo: 'PERFIL ESQUERDO (lado esquerdo do rosto voltado para a câmera)',
  };

  return `Valide esta foto de pré-consulta.

Tipo esperado: ${typeLabels[photoType]}

Verifique:
1. Rosto humano visível
2. Ângulo corresponde ao tipo "${photoType}"
3. Iluminação aceitável (só rejeite se MUITO escura ou estourada)
4. Foco aceitável (só rejeite se MUITO borrada)
5. Rosto completo, sem cortes
6. Sem óculos, boné, chapéu ou máscara no rosto
7. Fundo sem objetos visíveis (plantas, travesseiros, móveis, quadros, etc.)

Só rejeite por foco/iluminação em casos extremos. Rejeite por fundo sujo ou acessórios no rosto.

Responda APENAS com JSON válido.`;
}

/**
 * Resposta padrão quando a IA não consegue analisar (fail-open: aprovado por padrão)
 */
export const PHOTO_VALIDATION_FALLBACK = {
  approved: true,
  confidence: 0,
  issues: [] as string[],
  feedback_patient: 'Não foi possível validar a foto automaticamente. Ela será enviada para revisão.',
  face_detected: true,
  angle_correct: true,
  lighting_adequate: true,
  focus_adequate: true,
  face_fully_visible: true,
  background_clean: true,
};

/**
 * Interface tipada para o resultado da validação
 */
export interface PhotoValidationResult {
  approved: boolean;
  confidence: number;
  issues: string[];
  feedback_patient: string;
  face_detected: boolean;
  angle_correct: boolean;
  lighting_adequate: boolean;
  focus_adequate: boolean;
  face_fully_visible: boolean;
  background_clean: boolean;
}

/**
 * Valida e sanitiza a resposta da IA
 */
export function validatePhotoResponse(response: unknown): PhotoValidationResult {
  const fallback = PHOTO_VALIDATION_FALLBACK;

  if (!response || typeof response !== 'object') {
    return fallback;
  }

  const r = response as Record<string, unknown>;

  const validIssues = [
    'blur', 'bad_lighting', 'wrong_angle', 'face_cutoff',
    'obstruction', 'no_face', 'multiple_faces', 'too_far', 'too_close',
    'background_dirty',
  ];

  return {
    approved: typeof r.approved === 'boolean'
      ? r.approved
      : fallback.approved,
    confidence: typeof r.confidence === 'number' && r.confidence >= 0 && r.confidence <= 1
      ? r.confidence
      : fallback.confidence,
    issues: Array.isArray(r.issues)
      ? r.issues
          .filter((i): i is string => typeof i === 'string' && validIssues.includes(i))
          .slice(0, 5)
      : fallback.issues,
    feedback_patient: typeof r.feedback_patient === 'string'
      ? r.feedback_patient.slice(0, 500)
      : fallback.feedback_patient,
    face_detected: typeof r.face_detected === 'boolean'
      ? r.face_detected
      : fallback.face_detected,
    angle_correct: typeof r.angle_correct === 'boolean'
      ? r.angle_correct
      : fallback.angle_correct,
    lighting_adequate: typeof r.lighting_adequate === 'boolean'
      ? r.lighting_adequate
      : fallback.lighting_adequate,
    focus_adequate: typeof r.focus_adequate === 'boolean'
      ? r.focus_adequate
      : fallback.focus_adequate,
    face_fully_visible: typeof r.face_fully_visible === 'boolean'
      ? r.face_fully_visible
      : fallback.face_fully_visible,
    background_clean: typeof r.background_clean === 'boolean'
      ? r.background_clean
      : fallback.background_clean,
  };
}
