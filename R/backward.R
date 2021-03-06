source("R/checks.R")
source("R/utils.R")


#' Backward Selection Algorithm.
#'
#' @description
#' This is an implementation of the backward selection algorithm
#' in which you start with a full model and iteratively remove the
#' least useful feature at each step. This function is built for the specific case
#' of backward selection in linear regression models.
#'
#'
#' @param X_train Training data
#'
#'  A 2D matrix of (observations, features)
#'
#' @param y_train Target class for training data
#'
#'  A 1D array of target classes for X_train
#'
#' @param X_val Validation data
#'
#'  A 2D matrix of (observations, features)
#'
#' @param y_val Target class for validation data
#'
#'  A 1D array of target classes for X_val
#'
#' @param criterion Model selection criterion
#'  A criterion to measure relative model quality.
#'  'aic': use Akaike Information Criterion
#'  'bic': use Bayesian Information Criterion
#' @param min_change Smallest change in criterion score to be considered significant.
#'
#' @param n_features Number of features to allow.
#'
#' @param verbose
#'  if True, print additional information as selection occurs
#' @export
backward <- function(X_train, y_train, X_val, y_val,
                     n_features=0.5, min_change=NULL,
                     criterion='r-squared', verbose=TRUE){

    input_data_checks(X_train, y_train)
    input_data_checks(X_val, y_val)
    input_checks(n_features=n_features, min_change=min_change, criterion=criterion)
    S = 1:ncol(X_train)  # start with all features

    if (!is.null(n_features)){
        n_features <- parse_n_features(
            n_features=n_features, total=length(S)
        )
        min_change <- NULL
    }

    last_iter_score <- fit_and_score(
        S=S, feature=NULL, algorithm='backward', X_train=X_train,
        y_train=y_train, X_val=X_val, y_val=y_val, criterion=criterion
    )
    for (i in 1:ncol(X_train)){  # assume worst case to start.
        if (verbose){
            print(paste0(c("Iteration ", i), collapse=""))
        }

        # 1. Hunt for the least predictive feature.
        best = NULL
        for (j in S){
            score = fit_and_score(
                S=S, feature=j, algorithm='backward', X_train=X_train,
                y_train=y_train, X_val=X_val, y_val=y_val, criterion=criterion
            )
            if (is.null(best)){
                best <- c(j, score, score > last_iter_score)
            } else if (score > best[2]){
                best <- c(j, score, score > last_iter_score)
            }
        }
        to_drop <- best[1]
        best_new_score <- best[2]
        defeated_last_iter_score <- best[3]

        # 2a. Halting Blindly Based on `n_features`.
        if (!is.null(n_features)){
            S <- S[S != to_drop]
            last_iter_score = best_new_score
            if (length(S) == n_features){
                break
            } else {
                next # i.e., ignore criteria below.
            }
        }

        # 2b. Halt if the change is not longer considered significant.
        if (!is.null(min_change)){
            if (defeated_last_iter_score){
                if ((best_new_score - last_iter_score) < min_change){
                    break  # there was a change, but it was not large enough.
                } else {
                    S <- S[S != to_drop]
                    last_iter_score = best_new_score
                }
            } else {
                break
            }
        }

        # 2c. Halt if only one feature remains.
        if (length(S) == 1){
            break
        }
    }
    return(S)
}
