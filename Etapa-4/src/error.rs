// Grupo L

// Guilherme de Oliveira (00278301)
// Jean Pierre Comerlatto Darricarrere (00182408)

use thiserror::Error;

#[derive(Error, Debug)]
pub enum CompilerError {
    /*
    // Examples of usage:
    #[error("the data for key `{0}` is not available")]
    Redaction(String),
    #[error("invalid header (expected {expected:?}, found {found:?})")]
    InvalidHeader {
        expected: String,
        found: String,
    },
    */
    #[error("Sanity error: {0}")]
    SanityError(String),

    #[error("Reading input file failure.")]
    IoReadFailure(#[from] std::io::Error),

    #[error("Lexical error: {0}")]
    LexicalError(String),

    #[error("Parsing errors: {0}")]
    ParsingErrors(String),

    #[error("Semantic error: {0}")]
    SemanticError(String),

    #[error("Tree building error: {0}")]
    TreeBuildingError(String),

    #[error("Parser failed to evaluate expression")]
    EvalParserFailure,

    #[error("Error in scope, this should not happen")]
    FailedScoping,

    #[error("Usage of undeclared identifier: \"{id}\"\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorUndeclared {
        id: String,
        line: usize,
        col: usize,
        highlight: String,
    },

    #[error("Same-scope identifier redeclaration: \"{id}\"\nFirst occurrence at line {first_line}, column {first_col}:\n{first_highlight}\nAnd again at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorDeclared {
        id: String,
        first_line: usize,
        first_col: usize,
        first_highlight: String,
        second_line: usize,
        second_col: usize,
        second_highlight: String,
    },

    #[error("Variable identifier used as {second_class}: \"{id}\"\nFirst occurrence at line {first_line}, column {first_col}:\n{first_highlight}\nAnd again at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorVariable {
        id: String,
        first_line: usize,
        first_col: usize,
        first_highlight: String,
        second_class: String,
        second_line: usize,
        second_col: usize,
        second_highlight: String,
    },

    #[error("Vector identifier used as {second_class}: \"{id}\"\nFirst occurrence at line {first_line}, column {first_col}:\n{first_highlight}\nAnd again at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorVector {
        id: String,
        first_line: usize,
        first_col: usize,
        first_highlight: String,
        second_class: String,
        second_line: usize,
        second_col: usize,
        second_highlight: String,
    },

    #[error("Function identifier used as {second_class}: \"{id}\"\nFirst occurrence at line {first_line}, column {first_col}:\n{first_highlight}\nAnd again at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorFunction {
        id: String,
        first_line: usize,
        first_col: usize,
        first_highlight: String,
        second_class: String,
        second_line: usize,
        second_col: usize,
        second_highlight: String,
    },

    #[error("Incompatible type in attribution.\nExpected {valid_type} but received a \"{received_type}\".\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorWrongType {
        valid_type: String,
        received_type: String,
        line: usize,
        col: usize,
        highlight: String,
    },

    #[error("Invalid type conversion from \"string\" to \"{invalid_type}\"\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorStringToX {
        invalid_type: String,
        line: usize,
        col: usize,
        highlight: String,
    },

    #[error("Invalid type conversion from \"char\" to \"{invalid_type}\"\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorCharToX {
        invalid_type: String,
        line: usize,
        col: usize,
        highlight: String,
    },

    #[error("Invalid attribution of type \"string\" value, size exceeds that of variable declaration.\nVariable declaration size is {variable_size} and string size is {string_size}.\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorStringMax {
        line: usize,
        col: usize,
        highlight: String,
        variable_size: u32,
        string_size: u32,
    },

    #[error("Invalid usage of \"string\" type for vector declaration: \"{id}\"\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorStringVector {
        id: String,
        line: usize,
        col: usize,
        highlight: String,
    },

    #[error("Missing args in function call: \"{id}\"\nFunction definition at line {first_line}, column {first_col}:\n{first_highlight}\nCalled at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorMissingArgs {
        id: String,
        first_line: usize,
        first_col: usize,
        first_highlight: String,
        second_line: usize,
        second_col: usize,
        second_highlight: String,
    },

    #[error("Excess args in function call: \"{id}\"\nFunction definition at line {first_line}, column {first_col}:\n{first_highlight}\nCalled at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorExcessArgs {
        id: String,
        first_line: usize,
        first_col: usize,
        first_highlight: String,
        second_line: usize,
        second_col: usize,
        second_highlight: String,
    },

    #[error("Invalid type in function call arguments: \"{id}\"\nFunction definition at line {first_line}, column {first_col}:\n{first_highlight}\nCalled at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorWrongTypeArgs {
        id: String,
        first_line: usize,
        first_col: usize,
        first_highlight: String,
        second_line: usize,
        second_col: usize,
        second_highlight: String,
    },

    #[error("Function argument or parameter of invalid type \"string\": \"{id}\"\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorFunctionString {
        id: String,
        highlight: String,
        line: usize,
        col: usize,
    },

    #[error("Invalid argument for \"input\" command; expected variable of type \"int\" or \"float\", found \"{received_type}\";\nFirst occurrence at line {first_line}, column {first_col}:\n{first_highlight}\nAnd again at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorWrongParInput {
        received_type: String,
        first_highlight: String,
        first_line: usize,
        first_col: usize,
        second_highlight: String,
        second_line: usize,
        second_col: usize,
    },

    #[error("Invalid argument for \"output\" command; expected variable or literal of type \"int\" or \"float\", found \"{received_type}\";\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorWrongParOutputLit {
        received_type: String,
        highlight: String,
        line: usize,
        col: usize,
    },

    #[error("Invalid argument for \"output\" command; expected variable or literal of type \"int\" or \"float\", found \"{received_type}\";\nFirst occurrence at line {first_line}, column {first_col}:\n{first_highlight}\nAnd again at line {second_line}, column {second_col}:\n{second_highlight}")]
    SemanticErrorWrongParOutputId {
        received_type: String,
        first_highlight: String,
        first_line: usize,
        first_col: usize,
        second_highlight: String,
        second_line: usize,
        second_col: usize,
    },

    #[error("Invalid return for function; expected \"{expected_type}\", found \"{received_type}\";\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorWrrongParReturn {
        expected_type: String,
        received_type: String,
        line: usize,
        col: usize,
        highlight: String,
    },

    #[error("Invalid number parameter on shift command; expected number lower or equal to 16, found \"{received_value}\";\nOccurrence at line {line}, column {col}:\n{highlight}")]
    SemanticErrorWrongParShift {
        received_value: i32,
        highlight: String,
        line: usize,
        col: usize,
    },
}

impl CompilerError {
    pub fn error_code(&self) -> i32 {
        match *self {
            CompilerError::SanityError(_)
            | CompilerError::IoReadFailure(_)
            | CompilerError::LexicalError(_)
            | CompilerError::ParsingErrors(_)
            | CompilerError::SemanticError(_)
            | CompilerError::TreeBuildingError(_)
            | CompilerError::EvalParserFailure
            | CompilerError::FailedScoping => 1,
            CompilerError::SemanticErrorUndeclared { .. } => 10,
            CompilerError::SemanticErrorDeclared { .. } => 11,
            CompilerError::SemanticErrorVariable { .. } => 20,
            CompilerError::SemanticErrorVector { .. } => 21,
            CompilerError::SemanticErrorFunction { .. } => 22,
            CompilerError::SemanticErrorWrongType { .. } => 30,
            CompilerError::SemanticErrorStringToX { .. } => 31,
            CompilerError::SemanticErrorCharToX { .. } => 32,
            CompilerError::SemanticErrorStringMax { .. } => 33,
            CompilerError::SemanticErrorStringVector { .. } => 34,
            CompilerError::SemanticErrorMissingArgs { .. } => 40,
            CompilerError::SemanticErrorExcessArgs { .. } => 41,
            CompilerError::SemanticErrorWrongTypeArgs { .. } => 42,
            CompilerError::SemanticErrorFunctionString { .. } => 43,
            CompilerError::SemanticErrorWrongParInput { .. } => 50,
            CompilerError::SemanticErrorWrongParOutputLit { .. }
            | CompilerError::SemanticErrorWrongParOutputId { .. } => 51,
            CompilerError::SemanticErrorWrrongParReturn { .. } => 52,
            CompilerError::SemanticErrorWrongParShift { .. } => 53,
        }
    }
}
