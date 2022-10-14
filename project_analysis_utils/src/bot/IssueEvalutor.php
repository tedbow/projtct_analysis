<?php
namespace InfoUpdater\bot;

class IssueEvalutor {

  /**
   * The drupal.org term id for bot enabled issues.
   */
  public const TAG_AUTO_PATCHES_TERM_ID = 197887;

  /**
   * The drupal.org term id for Drupal 10 compatibility issues.
   */
  public const TAG_D10_COMPATIBILITY = 195558;

  // Issue statuses
  public const ISSUE_STATUS_ACTIVE = "1";
  public const ISSUE_STATUS_FIXED = "2";
  public const ISSUE_STATUS_CLOSED_DUPLICATE = "3";
  public const ISSUE_STATUS_POSTPONED = "4";
  public const ISSUE_STATUS_CLOSED_WONT_FIX = "5";
  public const ISSUE_STATUS_CLOSED_WORKS_AS_DESIGNED = "6";
  public const ISSUE_STATUS_CLOSED_FIXED = "7";
  public const ISSUE_STATUS_NEEDS_REVIEW = "8";
  public const ISSUE_STATUS_NEEDS_WORK = "13";
  public const ISSUE_STATUS_RTBC = "14";
  public const ISSUE_STATUS_PATCH_TO_BE_PORTED = "15";
  public const ISSUE_STATUS_POSTPONED_MAINTAINER_NEEDS_MORE_INFO = "16";
  public const ISSUE_STATUS_CLOSED_OUTDATED = "17";
  public const ISSUE_STATUS_CLOSED_CANNOT_REPRODUCE = "18";
  
  /**
   * Determines if an issue should be skipped.
   *
   * Will skip if in certain status or the TAG_AUTO_PATCHES_TERM_ID tag has been
   * removed.
   *
   * @param $issue
   *
   * @return bool
   */
  public static function skipIssue($issue) {
    if ($issue) {
      $not_skipped_statuses = [
        static::ISSUE_STATUS_NEEDS_REVIEW,
        static::ISSUE_STATUS_ACTIVE,
        static::ISSUE_STATUS_NEEDS_WORK,
        static::ISSUE_STATUS_RTBC,
      ];
      if (!in_array($issue->field_issue_status , $not_skipped_statuses)) {
        return TRUE;
      }
      // If bot tag was removed skip.
      return !static::issueHasTag($issue, static::TAG_AUTO_PATCHES_TERM_ID);
    }
    return TRUE;
  }

  /**
   * Determines if an issue has a tag.
   *
   * @param \stdClass $issue
   * @param int $tid
   *
   * @return bool
   */
  public static function issueHasTag(\stdClass $issue, int $tid) {
    foreach ($issue->taxonomy_vocabulary_9 as $tag) {
      if (((int) $tag->id) === $tid) {
        return TRUE;
      }
    }
    return FALSE;
  }
  
}
